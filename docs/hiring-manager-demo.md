# Hiring Manager Demo Guide

This guide packages InfraOps Agent Hub as a concise portfolio demo. Use it to show product judgment, systems thinking, safety design, and pragmatic implementation without pretending the MVP is production automation.

## Demo Goal

Show a safe incident-operations workflow that turns an infrastructure alert into:

- Structured triage.
- Release correlation.
- Runbook lookup.
- Approval-gated next steps.
- Audit evidence in Postgres.
- Clear operator handoff.

The strongest story is not "an AI fixes production." The strongest story is "an AI-assisted operations system can speed up diagnosis while preserving human approval, least privilege, auditability, and cost control."

## Demo Checklist

Before the call:

- Run `./scripts/validate-scaffold.sh`.
- Start the local stack with `./scripts/bootstrap-local.sh`.
- Run `./scripts/run-local-demo.sh` once.
- Import `n8n/workflows/incident-triage-workflow.example.json` into n8n.
- Open these files in editor tabs:
  - `README.md`
  - `docs/hiring-manager-demo.md`
  - `scripts/run-local-demo.sh`
  - `audit-schema/postgres.sql`
  - `n8n/workflows/incident-triage-workflow.example.json`
  - `docs/real-integration-path.md`
  - `docs/deployment.md`
- Capture screenshots into `screenshots/` if you want a static portfolio artifact.

Screenshots to capture:

- Repository root and README.
- n8n imported workflow canvas.
- Approval Gate Placeholder output.
- Terminal output from `./scripts/run-local-demo.sh`.
- Local Postgres `infraops_audit.audit_events` row.
- `docs/deployment.md` cost-control section.

## 2-Minute Walkthrough Script

0:00-0:20:

"InfraOps Agent Hub is a local-first MVP for AI-assisted infrastructure incident triage. The point is not autonomous remediation. The point is a safe operating loop: alert in, evidence gathered, runbook selected, human approval required for risky actions, and every step audited."

0:20-0:45:

"The demo incident is an InvoiceBridge 5xx spike. The local script reads a sample alert, structured error logs, and a high-5xx runbook. It produces mocked agent outputs for triage, release correlation, runbook lookup, next-step planning, and documentation. No AWS, GitHub, Slack, or LLM APIs are called."

0:45-1:15:

"The n8n workflow shows the same product flow visually. It starts with a webhook trigger, loads sample context, passes through AI placeholder nodes, blocks at the approval gate, and previews GitHub, Postgres, and Slack integration payloads without requiring credentials. This makes the demo importable and safe."

1:15-1:40:

"The audit schema is the control plane. It records agent runs, approvals, tool invocations, audit events, and incident snapshots. The runnable local demo inserts one audit event into Postgres, so there is a real persistence path even while external integrations remain mocked."

1:40-2:00:

"The production path is documented but intentionally not overbuilt. The next step would be read-only CloudWatch and GitHub adapters, Slack approval messages, an LLM adapter with redaction and schema validation, and deployment on one small VPS or Lightsail instance before considering managed AWS services."

## Architecture Explanation

```text
Sample/Webhook Alert
  |
  v
Context Normalization
  |
  +--> Sample Logs
  +--> Runbook Markdown
  +--> Release Metadata Placeholder
  |
  v
Mock Agent Outputs
  |
  +--> Triage
  +--> Release Correlation
  +--> Runbook Lookup
  +--> Next-Step Planning
  +--> Documentation
  |
  v
Approval Gate
  |
  +--> Read-only actions allowed
  +--> Production-impacting actions require human approval
  +--> Destructive actions blocked
  |
  v
Audit Event in Postgres
  |
  v
Operator Summary
```

Key files:

- `scripts/run-local-demo.sh`: End-to-end local demo path.
- `n8n/workflows/incident-triage-workflow.example.json`: Importable visual workflow.
- `audit-schema/postgres.sql`: Audit and approval data model.
- `runbooks/high-5xx-error-rate.md`: Human-readable operations guidance.
- `prompts/`: Future LLM behavior contracts.
- `docs/real-integration-path.md`: Path from mock adapters to real integrations.
- `docs/deployment.md`: Low-cost deployment plan.

## What This Project Proves Technically

- Can design a safe AI-assisted operations workflow with explicit control boundaries.
- Can separate read-only diagnosis from approval-required remediation.
- Can build an audit-first data model instead of treating logs as an afterthought.
- Can create runnable local demos that do not depend on paid APIs or live cloud access.
- Can structure n8n workflows for clear operator handoff without requiring credentials at import time.
- Can think through least-privilege IAM, GitHub, Slack, Postgres, and LLM integration paths.
- Can keep portfolio infrastructure cost low with a one-server deployment plan.
- Can document a path to production without prematurely building unnecessary platform complexity.

## What Is Mocked vs Real

Real in the MVP:

- Repository structure and documentation.
- Docker Compose stack for n8n and Postgres.
- Postgres audit schema.
- Local script execution.
- JSON sample alerts and logs.
- Runbook markdown.
- n8n workflow import file.
- Local Postgres audit insert from `scripts/run-local-demo.sh`.
- Safety checks in scripts.

Mocked or placeholder:

- AWS CloudWatch reads.
- GitHub issue creation.
- Slack message sending.
- LLM inference.
- Release lookup from a real deploy source.
- Production remediation.
- Human approval UI.
- Long-term backup automation.

Intentionally absent:

- Real secrets.
- Destructive automation.
- Production cloud writes.
- Autonomous rollback, restart, scaling, or config mutation.

## Resume Bullets

Use or adapt these depending on the role:

- Built InfraOps Agent Hub, a local-first AI-assisted incident triage MVP with n8n, Docker Compose, Postgres audit logging, runbooks, prompt contracts, and safe mock adapters.
- Designed an approval-gated infrastructure operations workflow that separates read-only diagnosis from production-impacting actions and records incident evidence in a structured audit schema.
- Created an importable credential-free n8n workflow demonstrating webhook alert ingestion, mock agent triage, release correlation, runbook lookup, approval gates, and placeholder GitHub, Slack, and Postgres integrations.
- Implemented a deterministic local demo script that reads sample alerts/logs/runbooks, generates mocked agent outputs, inserts an audit event into Postgres, and prints an operator-ready incident summary.
- Documented a least-privilege productionization path for AWS CloudWatch, GitHub, Slack, Postgres, LLM providers, approval enforcement, and low-cost Lightsail/VPS deployment.

## Interview Talking Points

Safety:

- "I treated the approval gate as a system boundary, not just a prompt instruction."
- "The agent can recommend, but adapters and policy decide what can execute."
- "Audit writes are mandatory before external side effects."

Pragmatism:

- "I kept the first deployment to one VPS because the MVP does not need RDS, NAT Gateway, ALB, ECS, or OpenSearch yet."
- "The demo is runnable without paid APIs, which makes it reliable in an interview."

Product judgment:

- "Operators need confidence and traceability more than they need a flashy autonomous agent."
- "The workflow is designed to make the next human action obvious."

Technical depth:

- "The mock adapters define contracts for later real adapters."
- "The schema separates agent runs, approvals, tool invocations, audit events, and incident snapshots."
- "The n8n workflow is credential-free by design so it can be imported safely."

## Suggested Live Demo Flow

1. Start at `README.md` and explain the product in one sentence.
2. Open `sample-alerts/invoicebridge-5xx-alert.json` and `sample-logs/invoicebridge-errors.json`.
3. Run:

   ```bash
   ./scripts/run-local-demo.sh
   ```

4. Point out the final summary and audit record ID.
5. Open `audit-schema/postgres.sql` and explain the audit model.
6. Open n8n and show the importable workflow.
7. Click through the approval gate and placeholders.
8. Open `docs/real-integration-path.md` and explain how real integrations would be added safely.
9. Open `docs/deployment.md` and explain the low-cost portfolio deployment path.

## Next Steps To Productionize

Phase 1: Read-only integrations.

- Add CloudWatch read-only alarm and metric adapter.
- Add GitHub read-only release and workflow-run adapter.
- Add log redaction before persistence or LLM context.
- Add adapter unit tests with denied write scenarios.

Phase 2: Real approval flow.

- Add approval request API and UI.
- Add Slack approval message drafts.
- Capture approver identity, expiration, and decision state.
- Enforce approval checks immediately before any external write.

Phase 3: LLM adapter.

- Add provider abstraction.
- Add schema validation for model output.
- Add prompt injection handling for logs and issue text.
- Add per-incident token and cost budgets.

Phase 4: Controlled writes.

- Enable GitHub issue creation after approval.
- Enable Slack incident summaries after approval.
- Keep infrastructure mutations disabled until policy tests and rollback playbooks are mature.

Phase 5: Operations.

- Automate backups and restore tests.
- Add deployment health checks.
- Add audit retention policy.
- Add monitoring for failed workflows, failed audit writes, and disk usage.

## Common Questions

Why not use a real LLM now?

- The MVP proves the workflow and safety boundaries first. Adding an LLM before redaction, schema validation, and approval enforcement would add risk without proving the core system.

Why n8n?

- It makes the incident flow visible to non-specialists and lets the demo show workflow intent without building a custom UI too early.

Why local Postgres?

- It gives a real audit persistence path while keeping the demo inexpensive and portable.

Why not use AWS managed services immediately?

- For a hiring-manager demo, the signal is architecture judgment. One small VPS is cheaper, simpler, and enough to prove the core product loop.
