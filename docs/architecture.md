# Architecture

InfraOps Agent Hub is organized around a safe incident operations loop:

```text
Alert -> Triage -> Runbook Match -> Approval Gate -> Audit Record -> Human Action
```

## Components

- Alert sources: Mock alert payloads in `sample-alerts/`.
- Evidence sources: Mock log excerpts in `sample-logs/`.
- Hosted demo UI: `demo.html`, `assets/demo.js`, and `assets/demo-engine.mjs`.
- Safe demo API: Cloudflare Pages Function in `functions/api/run-demo-incident.js`.
- Workflow layer: n8n example workflow in `n8n/workflows/`.
- Agent layer: Prompt contracts in `prompts/`.
- Operations layer: Human runbooks in `runbooks/`.
- Audit layer: local/hosted demo Postgres schema in `audit-schema/postgres.sql`; production can use a separate AWS-native audit-store adapter when governance requirements justify it.
- Safety layer: Approval gate policy documented in `docs/safety-and-approval-model.md`.

## Data Flow

1. A mock alert enters the hosted demo, CLI demo, or n8n workflow.
2. The packet generator summarizes alert and log evidence.
3. The workflow selects the high-5xx runbook.
4. The plan separates read-only steps from approval-required and blocked actions.
5. The approval gate prepares a human review packet.
6. Audit records or audit previews capture the run, decision boundary, and proposed tool actions.

## Integration Boundary

Live integrations are intentionally absent. Future adapters should sit behind explicit feature flags and must default to mock mode.

Proposed future adapter boundaries:

- `aws-readonly-adapter`: read-only CloudWatch, ECS, RDS, and IAM context.
- `slack-approval-adapter`: drafts approval messages and waits for human decision.
- `github-followup-adapter`: creates issues after approval.
- `llm-provider-adapter`: calls approved model providers with redaction and audit capture.
- `postgres-audit-store`: writes standard Postgres audit records through `DATABASE_URL`.
- `aws-native-audit-store`: future production adapter for DynamoDB/S3/EventBridge-style audit storage when AWS governance matters more than demo Postgres portability.

No adapter should bypass the approval gate.

See `docs/database-portability.md` for the Neon evaluation path and AWS RDS production migration target.
