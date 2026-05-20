# Architecture

InfraOps Agent Hub is organized around a safe incident operations loop:

```text
Alert -> Triage -> Runbook Match -> Approval Gate -> Audit Record -> Human Action
```

## Components

- Alert sources: Mock alert payloads in `sample-alerts/`.
- Evidence sources: Mock log excerpts in `sample-logs/`.
- Workflow layer: n8n example workflow in `n8n/workflows/`.
- Agent layer: Prompt contracts in `prompts/`.
- Operations layer: Human runbooks in `runbooks/`.
- Audit layer: Postgres schema in `audit-schema/postgres.sql`.
- Safety layer: Approval gate policy documented in `docs/safety-and-approval-model.md`.

## Data Flow

1. A mock alert enters the workflow.
2. The triage prompt summarizes the alert and selects a runbook.
3. The remediation prompt drafts a plan but marks production actions as approval-required.
4. The approval prompt prepares a human review packet.
5. Audit records capture the run, decision, and proposed tool actions.

## Integration Boundary

Live integrations are intentionally absent. Future adapters should sit behind explicit feature flags and must default to mock mode.

Proposed future adapter boundaries:

- `aws-readonly-adapter`: read-only CloudWatch, ECS, RDS, and IAM context.
- `slack-approval-adapter`: drafts approval messages and waits for human decision.
- `github-followup-adapter`: creates issues after approval.
- `llm-provider-adapter`: calls approved model providers with redaction and audit capture.

No adapter should bypass the approval gate.
