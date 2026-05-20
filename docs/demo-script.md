# Demo Script

Use this checklist to capture a clear portfolio walkthrough of the local mock demo. The goal is to show the safety boundary and product flow, not production automation.

## Setup Shots

- Repository root with `README.md`, `scripts/`, `n8n/`, `runbooks/`, `sample-alerts/`, and `sample-logs/` visible.
- `docker compose` local stack running with n8n and Postgres.
- n8n import dialog showing `n8n/workflows/incident-triage-workflow.example.json`.

## n8n Workflow Shots

- Full workflow canvas after import.
- Webhook Trigger node configuration with path `infraops-agent-hub/incident-triage`.
- Sample Alert Context node showing the InvoiceBridge 5xx alert fallback.
- Sample Log and Runbook Placeholders node showing local sample sources.
- AI placeholder zone showing triage, release correlation, and planning nodes.
- Approval Gate Placeholder output showing `HUMAN_APPROVAL_REQUIRED`.
- GitHub Issue Placeholder output showing issue title and body preview.
- Postgres Audit Insert Placeholder output showing audit table and event type preview.
- Documentation and Slack Summary Placeholder output showing the final incident summary and Slack preview.

## Terminal Demo Shots

- Running `./scripts/bootstrap-local.sh`.
- Running `./scripts/run-local-demo.sh`.
- Final incident summary printed by the local demo script.
- Audit record ID printed by the script.

## Database Shots

- Query result from `infraops_audit.audit_events` showing the inserted local demo record.
- Expanded `evidence` JSON showing triage, release correlation, runbook lookup, next-step planning, documentation, and safety fields.

## Safety Shots

- Workflow note stating no real AWS, GitHub, Slack, Postgres, or LLM calls are made by the imported n8n workflow.
- Approval gate output showing production-impacting actions blocked until human approval.
- README section describing mock-only behavior and local demo commands.

## Suggested Narrative

1. Show the incoming InvoiceBridge 5xx alert.
2. Show the workflow loading sample logs and runbook placeholders.
3. Show deterministic mock agent outputs.
4. Show the approval gate blocking production-impacting actions.
5. Show placeholder payloads for GitHub, Postgres, and Slack.
6. Run the shell demo to insert one real local audit event.
7. Close on the final incident summary and audit evidence.
