# InfraOps Agent Hub

InfraOps Agent Hub is a local-first MVP scaffold for an AI-assisted infrastructure operations console. It shows how alerts, logs, prompts, approval gates, runbooks, and audit records can fit together without making live AWS, Slack, GitHub, or LLM calls.

This repository is intentionally safe by default. Every integration is mocked, every production-impacting action requires human approval, and all sample workflows are designed for local demonstration only.

## MVP Scope

Included:

- Local Docker Compose stack for n8n and Postgres.
- Example n8n workflow for incident triage using mock alert data.
- Prompt templates for triage, remediation planning, approvals, and post-incident summaries.
- Runbooks for common infrastructure incidents.
- Sample alerts and logs for demos.
- Postgres audit schema for agent runs, approvals, tool invocations, and audit events.
- Safe helper scripts for local bootstrap, validation, mock triage, approval checks, and local schema setup.
- Product and engineering documentation for the MVP.

Not included yet:

- Real AWS API calls.
- Real Slack messages.
- Real GitHub issue or pull request automation.
- Real LLM provider calls.
- Production remediation automation.

## Safety Principles

- Mock mode is the only supported mode in this scaffold.
- No real secrets are committed.
- Scripts do not run destructive infrastructure commands.
- Production-impacting actions are blocked unless a human approval record exists.
- Workflow examples produce recommendations and audit previews, not live changes.
- All production integrations are represented as placeholders for future implementation.

## Repository Map

```text
.
|-- audit-schema/
|   `-- postgres.sql
|-- docs/
|   |-- architecture.md
|   |-- audit-logging.md
|   |-- integration-placeholders.md
|   |-- local-development.md
|   |-- real-integration-path.md
|   |-- roadmap.md
|   `-- safety-and-approval-model.md
|-- n8n/
|   `-- workflows/
|       `-- incident-triage-workflow.example.json
|-- prompts/
|   |-- README.md
|   |-- agent-system.md
|   |-- approval-request.md
|   |-- incident-triage.md
|   |-- post-incident-summary.md
|   `-- remediation-plan.md
|-- runbooks/
|   |-- README.md
|   |-- approval-gate.md
|   |-- ecs-cpu-saturation.md
|   |-- high-5xx-error-rate.md
|   |-- incident-triage.md
|   |-- post-incident-review.md
|   `-- rds-storage-pressure.md
|-- sample-alerts/
|-- sample-logs/
|-- scripts/
|-- config.example.env
|-- docker-compose.yml
`-- README.md
```

## Quick Start

Prerequisites:

- Docker Desktop or a compatible Docker engine.
- Bash.
- Python 3.
- Optional: `psql` for applying the local audit schema.

Start local services:

```bash
cp config.example.env .env
./scripts/bootstrap-local.sh
```

Open n8n:

- URL: http://localhost:5678
- User: `local-admin`
- Password: `local-password-change-me`

Import the example workflow:

1. Open n8n locally.
2. Import `n8n/workflows/incident-triage-workflow.example.json`.
3. Run it manually.
4. Review the generated mock triage, approval gate summary, and audit preview.

Run a local mock triage without n8n:

```bash
./scripts/mock-triage.sh sample-alerts/cloudwatch-high-cpu.json
```

Run the smallest local incident demo:

```bash
./scripts/bootstrap-local.sh
./scripts/run-local-demo.sh
```

The demo reads:

- `sample-alerts/invoicebridge-5xx-alert.json`
- `sample-logs/invoicebridge-errors.json`
- `runbooks/high-5xx-error-rate.md`

It then produces deterministic mocked outputs for triage, release correlation, runbook lookup, next-step planning, and documentation. The script inserts one `infraops_audit.audit_events` record into local Postgres and prints the final incident summary. It refuses non-local database URLs and does not call real AWS, GitHub, Slack, or LLM APIs.

Validate the scaffold:

```bash
./scripts/validate-scaffold.sh
```

Apply the audit schema to local Postgres:

```bash
DATABASE_URL=postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub ./scripts/apply-audit-schema-local.sh
```

## Product Concept

InfraOps Agent Hub is designed for teams that need faster incident triage without giving an autonomous system unchecked production access. The hub collects alerts and logs, asks an agent to reason over current context, maps findings to runbooks, drafts an approval request, and records every step in an audit trail.

The intended operator experience:

1. An alert enters the hub.
2. The agent classifies severity and likely impact.
3. The agent gathers safe context from approved sources.
4. The agent proposes a read-only diagnosis and a remediation plan.
5. A human reviews and approves any production-impacting action.
6. The hub records the decision, evidence, and final outcome.

## Local Services

Docker Compose starts:

- `postgres`: local audit database.
- `n8n`: local workflow runner.
- `adminer`: optional database UI profile.

Start the optional Adminer UI:

```bash
docker compose --profile tools up -d adminer
```

Adminer will be available at http://localhost:8080.

## Approval Model

The MVP separates actions into three classes:

- `read_only`: Safe inspection, summarization, and local mock analysis.
- `approval_required`: Any action that could affect production systems, customer data, cost, deployment state, access, or external communication.
- `blocked`: Destructive, irreversible, or insufficiently specified actions.

The scaffold only implements `read_only` and mock `approval_required` flows. Future production integrations must enforce the same approval boundary in code, workflow configuration, and audit records.

## Audit Model

The audit schema captures:

- Agent run metadata.
- Input fingerprints and context references.
- Tool invocation intent.
- Approval requests and decisions.
- Immutable audit events.
- Incident snapshots.

See `docs/audit-logging.md` and `audit-schema/postgres.sql`.

## Safe Scripts

All scripts use `set -euo pipefail` and are scoped to local development.

- `scripts/bootstrap-local.sh`: Creates `.env` from the example if needed and starts local services.
- `scripts/validate-scaffold.sh`: Validates JSON, shell syntax, compose config, and obvious secret patterns.
- `scripts/mock-triage.sh`: Produces a deterministic mock triage response from a sample alert.
- `scripts/run-local-demo.sh`: Runs the InvoiceBridge 5xx mock incident demo and writes one local audit event.
- `scripts/approval-gate.sh`: Demonstrates blocking production-impacting actions without human approval.
- `scripts/apply-audit-schema-local.sh`: Applies the schema only to a local Postgres URL.

## Roadmap

The next implementation phase should add real integrations behind explicit feature flags:

1. Read-only AWS inventory and CloudWatch context retrieval.
2. Slack approval request drafts with manual send controls.
3. GitHub issue creation for post-incident follow-up.
4. LLM provider adapter with redaction and audit capture.
5. Policy engine for approval checks.
6. End-to-end tests for the approval boundary.

## Portfolio Notes

This scaffold is built to show product judgment as much as technical structure: local demoability, safety boundaries, auditability, and realistic incident operations are present from the first commit. The system is intentionally incomplete where production risk would otherwise be introduced.
