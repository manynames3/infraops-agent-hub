# Local Development

## Setup

```bash
cp config.example.env .env
./scripts/bootstrap-local.sh
```

Local URLs:

- n8n: http://localhost:5678
- Adminer: http://localhost:8080 when started with the `tools` profile

## Import Workflow

In n8n, import:

```text
n8n/workflows/incident-triage-workflow.example.json
```

The workflow is inactive by default and uses only mock nodes.

## Validate

```bash
./scripts/validate-scaffold.sh
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

## Apply Local Audit Schema

Start Postgres, then run:

```bash
DATABASE_URL=postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub ./scripts/apply-audit-schema-local.sh
```

The script refuses non-local database URLs.
