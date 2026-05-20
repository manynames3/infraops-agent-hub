# Local Development

## Setup

```bash
cp config.example.env .env
make up
```

Local URLs:

- n8n: http://localhost:5678
- Adminer: http://localhost:8080 when started with the `tools` profile
- Deployed landing page: https://infraops-agent-hub.pages.dev/

To preview the landing page locally without Docker:

```bash
python3 -m http.server 8877
```

Then open http://localhost:8877.

## Import Workflow

In n8n, import:

```text
n8n/workflows/incident-triage-workflow.example.json
```

The workflow is inactive by default and uses only mock nodes.

The imported workflow starts with a webhook trigger at:

```text
/webhook/infraops-agent-hub/incident-triage
```

It uses credential-free placeholder nodes for log/runbook loading, AI outputs, approval, GitHub Issue creation, Postgres audit insert preview, and Slack summary preview.

## Validate

```bash
make validate
```

Validation checks:

- JSON syntax.
- Shell syntax.
- `set -euo pipefail` in shell scripts.
- Docker Compose configuration when Compose is available.
- Obvious committed secret patterns.

## Run Mock Triage

```bash
./scripts/mock-triage.sh sample-alerts/rds-storage-pressure.json
```

The command prints deterministic JSON and does not call external services.

## Run Local Incident Demo

```bash
make demo
```

The demo reads the InvoiceBridge 5xx alert, sample logs, and high-5xx runbook. It prints deterministic mocked agent outputs and inserts one audit event into local Postgres when the local stack is running.

## Apply Local Audit Schema

Start Postgres, then run:

```bash
DATABASE_URL=postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub ./scripts/apply-audit-schema-local.sh
```

The script refuses non-local database URLs.
