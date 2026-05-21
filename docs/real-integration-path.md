# Real Integration Path

This guide describes how to replace the MVP mock adapters with real integrations while preserving the safety model. It is implementation guidance only. Do not commit real credentials, webhook URLs, API keys, private tokens, or account IDs.

Status: draft implementation plan as of 2026-05-20.

## Non-Negotiable Constraints

- Keep mock mode as the default.
- Add each real adapter behind an explicit feature flag.
- Start with read-only ingestion before any write-capable integration.
- Require human approval before production-impacting actions.
- Record every adapter request, approval decision, and external write in `infraops_audit.audit_events`.
- Keep credentials in a secret manager or environment variables, never in source control.

## Environment Variables

Use names like these, but keep values outside Git:

```text
ENABLE_REAL_AWS_CALLS=false
ENABLE_REAL_GITHUB_CALLS=false
ENABLE_REAL_SLACK_CALLS=false
ENABLE_REAL_LLM_CALLS=false

AWS_REGION=us-east-1
AWS_ROLE_ARN=arn:aws:iam::<account-id>:role/infraops-agent-hub-readonly

GITHUB_OWNER=example-org
GITHUB_REPO=example-repo
GITHUB_TOKEN=<stored outside repo>

SLACK_WEBHOOK_URL=<stored outside repo>

DATABASE_URL=postgres://<user>:<password>@<host>:5432/<database>

LLM_PROVIDER=openai-compatible
LLM_API_KEY=<stored outside repo>
LLM_MODEL=<approved-model-id>
```

## Adapter Rollout Order

1. `mock`: current deterministic local behavior.
2. `dry_run`: real authentication checks, no external writes.
3. `read_only`: read metrics, logs, release metadata, and issue state.
4. `approval_required_write`: create Slack messages or GitHub issues only after approval.
5. `blocked`: infrastructure mutations remain blocked until a separate control plane exists.

## AWS CloudWatch Read-Only Setup

Purpose:

- Read CloudWatch alarms and metrics.
- Correlate alert context with service health.
- Avoid infrastructure mutation.

Recommended IAM shape:

- Prefer an IAM role assumed by the deployed workload.
- Restrict by account and region where possible.
- Use a customer-managed policy instead of broad AWS managed policies.
- Exclude write actions such as `PutMetricAlarm`, `DeleteAlarms`, `SetAlarmState`, `EnableAlarmActions`, and `DisableAlarmActions`.

Example read-only policy skeleton:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadCloudWatchMetricsAndAlarms",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "cloudwatch:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ReadCloudWatchLogsForApprovedGroups",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:FilterLogEvents",
        "logs:GetLogEvents",
        "logs:StartQuery",
        "logs:GetQueryResults",
        "logs:StopQuery"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:<account-id>:log-group:/aws/ecs/invoicebridge-*",
        "arn:aws:logs:us-east-1:<account-id>:log-group:/aws/lambda/invoicebridge-*"
      ]
    }
  ]
}
```

Implementation notes:

- Start by reading alarms with `DescribeAlarms` and metrics with `GetMetricData`.
- Build a metric allow list per service instead of accepting arbitrary metric queries from prompts.
- Add log redaction before storing evidence or sending context to an LLM.
- Store only log excerpts needed for incident review.
- Record AWS request IDs and query windows in the audit event evidence.

Official references:

- [CloudWatch service authorization reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazoncloudwatch.html)
- [CloudWatch Logs service authorization reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazoncloudwatchlogs.html)
- [CloudWatch GetMetricData API](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_GetMetricData.html)
- [CloudWatch ListMetrics CLI reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/list-metrics.html)

## GitHub API Token Permissions

Purpose:

- Read release, commit, workflow, and issue context.
- Optionally create follow-up issues after human approval.

Recommended token shape:

- Prefer a GitHub App installation token for production.
- If using a fine-grained personal access token for an MVP, scope it to one repository.
- Set an expiration date and rotate it.
- Store it as `GITHUB_TOKEN` outside the repo.

Minimum permissions by feature:

| Feature | Repository permission |
| --- | --- |
| Read repository metadata | `Metadata: read` |
| Read commits and release context | `Contents: read` |
| Read GitHub Actions workflow runs | `Actions: read` |
| Create incident follow-up issue | `Issues: write` |
| Comment on issue after approval | `Issues: write` |

Avoid:

- `Administration`.
- `Contents: write`.
- `Workflows: write`.
- Organization-wide access.
- Tokens that can access unrelated repositories.

Implementation notes:

- Keep GitHub issue creation behind the approval gate unless the issue is purely internal and approved by policy.
- Include `X-GitHub-Api-Version` in REST requests.
- Capture the issue URL, API request ID if available, and token permission profile in audit evidence.
- Treat secondary rate limiting as a stop condition and back off.

Official references:

- [Permissions for fine-grained personal access tokens](https://docs.github.com/rest/overview/permissions-required-for-fine-grained-personal-access-tokens)
- [Create an issue REST endpoint](https://docs.github.com/en/rest/issues/issues#create-an-issue)
- [List commits REST endpoint](https://docs.github.com/en/rest/commits/commits)
- [Workflow runs REST endpoints](https://docs.github.com/rest/actions/workflow-runs/)

## Slack Webhook Setup

Purpose:

- Send concise incident summaries to a fixed incident channel.
- Avoid broad chat permissions during the MVP.

Recommended setup:

1. Create a Slack app for the workspace.
2. Enable Incoming Webhooks.
3. Install the app into a development or incident sandbox channel.
4. Store the generated webhook URL as `SLACK_WEBHOOK_URL` outside the repo.
5. Send only approved summary messages.

Safety rules:

- Never commit the webhook URL.
- Use one channel-specific webhook per environment.
- Do not include secrets, raw customer data, or full logs in Slack messages.
- Treat customer-facing or executive status messages as approval-required.
- Store Slack message timestamp or response metadata in the audit event when available.

Implementation notes:

- Incoming webhooks post to the channel selected during app installation.
- Use Slack blocks for readability, but keep a plain-text fallback.
- Validate message length and redact before sending.
- In local and CI tests, replace the webhook client with a mock.

Official references:

- [Slack incoming webhooks guide](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks)
- [Slack `incoming-webhook` scope](https://docs.slack.dev/reference/scopes/incoming-webhook)

## Postgres Audit Storage

Purpose:

- Store an append-style audit trail for incident handling.
- Preserve agent outputs, approvals, tool intents, and external integration results.

Recommended database roles:

```sql
CREATE ROLE infraops_audit_writer LOGIN PASSWORD '<stored outside repo>';
GRANT USAGE ON SCHEMA infraops_audit TO infraops_audit_writer;
GRANT INSERT ON infraops_audit.audit_events TO infraops_audit_writer;
GRANT INSERT ON infraops_audit.incident_snapshots TO infraops_audit_writer;
GRANT INSERT, SELECT ON infraops_audit.agent_runs TO infraops_audit_writer;
GRANT INSERT, SELECT, UPDATE ON infraops_audit.approval_requests TO infraops_audit_writer;
GRANT INSERT, SELECT, UPDATE ON infraops_audit.tool_invocations TO infraops_audit_writer;
```

Implementation notes:

- Keep the application on standard Postgres through one `DATABASE_URL`; see `docs/database-portability.md`.
- Use Neon for low-cost hosted evaluation and AWS RDS PostgreSQL when production buyers require AWS-native controls.
- Split runtime roles from migration/admin roles.
- Runtime should not own tables.
- Runtime should not have broad schema changes.
- Use TLS for remote Postgres.
- Add regular backups before storing production incident records.
- Use `jsonb` evidence fields for structured context, but redact before insert.
- Consider table partitioning or retention policies once audit volume grows.
- Treat audit writes as mandatory for external writes. If audit insert fails, block the external action.

Official reference:

- [PostgreSQL GRANT documentation](https://www.postgresql.org/docs/current/sql-grant.html)

## LLM Provider Setup

Purpose:

- Replace deterministic mock outputs with provider-backed reasoning while preserving auditability and approval gates.

Recommended setup:

- Store provider credentials as `LLM_API_KEY` outside the repo.
- Load keys only server-side.
- Keep model name and prompt version in config.
- Add request timeout, retry, and max-token limits.
- Add a per-incident and per-day budget guard.
- Log provider, model, prompt version, redaction version, input fingerprint, and output fingerprint.
- Do not store full prompts if they contain sensitive data. Store references and redacted excerpts.

Adapter contract:

```text
input: redacted incident context, allowed tools, prompt version
output: structured JSON with observations, inferences, recommendations, approval requirements
side effects: none
```

Safety rules:

- The LLM adapter must not call external tools directly.
- Tool execution must happen in separate typed adapters.
- Any recommended production-impacting action must be downgraded to `approval_required`.
- Prompt injection from logs, alerts, issues, or Slack must be treated as untrusted text.
- Validate model output against a schema before using it.

Official references:

- [OpenAI API authentication guidance](https://platform.openai.com/docs/api-reference/introduction)
- [OpenAI rate limits guidance](https://platform.openai.com/docs/guides/rate-limits)

## Approval Gate Design

The approval gate is the core control boundary. It should sit between recommendation and execution, not inside the LLM prompt alone.

Required inputs:

- Incident ID.
- Actor identity.
- Proposed action.
- Action class.
- Environment.
- Risk summary.
- Rollback plan.
- Expiration time.
- Required approver group.

Decision states:

- `pending`.
- `approved`.
- `rejected`.
- `expired`.
- `withdrawn`.

Enforcement rules:

- `read_only` can proceed without approval, but must still be audited.
- `approval_required` cannot execute until a valid approval exists.
- `blocked` cannot execute even with approval.
- Approval must expire.
- Approval applies only to the exact action, service, environment, and time window requested.
- The approver cannot be the same automation identity that requested the action.
- A failed audit write blocks the action.

Implementation pattern:

1. Adapter classifies action.
2. Policy engine validates classification.
3. Approval request is inserted.
4. Human decision is captured.
5. Action adapter re-checks approval immediately before execution.
6. Audit event records the final result.

## Least-Privilege Permissions

Use least privilege at every boundary:

- One AWS role for read-only context.
- Separate AWS role for future remediation, disabled by default.
- One GitHub token or GitHub App installation per repository.
- One Slack webhook per channel and environment.
- Separate Postgres migration and runtime users.
- Separate LLM project or API key for this app.
- No credential reuse across local, staging, and production.

Review process:

- Document every permission in a permission matrix.
- Remove unused permissions after observing real access patterns.
- Use IAM Access Analyzer for AWS policy review and unused access findings.
- Rotate tokens and keys on a schedule.
- Require pull request review for permission changes.

Official references:

- [AWS IAM managed policy guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-iam-awsmanpol.html)
- [AWS IAM Access Analyzer findings](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-findings.html)

## Cost-Control Notes for Lightsail Deployment

Lightsail is suitable for a small portfolio or team demo if the deployment stays simple and bounded.

Recommended deployment shape:

- One small Lightsail instance for the app and workflow runner.
- Neon Postgres for low-cost hosted evaluation, or AWS RDS PostgreSQL when production controls justify it.
- Keep n8n, adapter API, and local worker count low.
- Disable high-frequency polling by default.
- Prefer webhook-driven flows.
- Retain logs for a short fixed window.
- Keep sample data small.

Cost controls:

- Set an AWS Budget for the account before deploying.
- Review Lightsail usage in AWS Billing and Cost Management.
- Use Lightsail metric alarms for instance CPU, burst capacity, disk, and network symptoms.
- Add application-level request and token budgets before enabling LLM calls.
- Set max daily LLM spend in the provider dashboard where available.
- Cap scheduled workflow frequency.
- Disable real integrations in staging when not actively testing.
- Stop or delete unused instances, disks, snapshots, static IPs, and load balancers.
- Avoid storing large log payloads in Postgres.

Operational guardrails:

- Treat cost spikes as incidents.
- Alert on unexpected outbound network growth.
- Separate demo and production AWS accounts.
- Keep the first real deployment read-only until audit volume and LLM cost are understood.

Official references:

- [Lightsail billing and usage](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-your-amazon-lightsail-bill.html)
- [Lightsail metric alarms](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-alarms.html)
- [AWS Budgets setup](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html)

## Readiness Checklist

- Mock mode remains the default.
- Real adapters are feature-flagged.
- No secrets are committed.
- CloudWatch access is read-only.
- GitHub token is repository-scoped and expires.
- Slack webhook points to a non-production or approved incident channel.
- Postgres runtime role has limited grants.
- LLM calls have redaction, schema validation, rate limits, and budget limits.
- Approval gate blocks all production-impacting actions.
- Audit write failure blocks external writes.
- Lightsail deployment has a budget and alarms.
