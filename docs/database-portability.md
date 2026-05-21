# Database Portability

InfraOps Agent Hub should treat Postgres as a portable audit store, not as a commitment to one hosting provider.

The near-term hosted demo can use Neon because it is cheap, simple, and speaks standard Postgres. The production path can move to AWS RDS or Aurora PostgreSQL when buyer requirements justify AWS-native controls.

## Decision

Use standard PostgreSQL with one runtime connection string:

```text
DATABASE_URL=postgres://...
```

Do not bind product logic to a Neon SDK, Supabase client, Cloudflare D1, DynamoDB, or provider-specific database feature. The application should talk to a small audit-store adapter that executes standard SQL against the schema in `audit-schema/postgres.sql`.

## Supported Targets

| Target | Use case | Why |
| --- | --- | --- |
| Local Docker Postgres | Local development and interviews | Matches the repository demo and is easy to reset. |
| Neon Postgres | Hosted evaluation demo and early paid pilot | Real Postgres with low idle cost and minimal operations. |
| AWS RDS PostgreSQL | Production AWS deployment | Private networking, KMS, IAM-adjacent controls, backups, CloudWatch, and stronger enterprise fit. |
| Aurora PostgreSQL | Later scale option | Only after RDS limits or enterprise availability requirements justify it. |

## Portability Rules

- Keep schema changes in SQL migration files.
- Use standard Postgres types where possible.
- Keep `jsonb` for evidence payloads, packet snapshots, and provider-specific metadata.
- Keep runtime configuration in environment variables.
- Do not hardcode hostnames, ports, users, or database names.
- Do not depend on Neon branching, Neon Auth, Supabase Realtime, D1 SQL dialect, or RDS-only extensions in core product logic.
- Keep Cloudflare Pages/Workers demo persistence separate from the production AWS deployment path.

## Current Demo Behavior

The live demo at `demo.html` generates an incident packet from repository sample data and creates an audit-event preview shaped like `infraops_audit.audit_events`.

Persistence modes:

- Local Docker demo: writes one audit record into local Postgres through `scripts/run-local-demo.sh`.
- Hosted browser demo: stores an audit preview locally in the browser if the API is unavailable.
- Hosted Pages Function demo: returns a server-side audit preview by default.
- Hosted Neon demo: can persist one audit event through the Neon serverless Postgres adapter when explicitly enabled.
- Production path: writes to standard Postgres only after the adapter is explicitly enabled and tested.

This keeps the public demo safe. It does not silently write to external systems.

## Hosted Neon Demo Configuration

The hosted Pages Function keeps audit writes disabled unless all of these are set outside the repo:

```text
DATABASE_PROVIDER=neon
DATABASE_URL=postgres://<user>:<password>@<host>/<database>?sslmode=require
ENABLE_HOSTED_AUDIT_WRITES=true
```

Before enabling writes:

1. Create the Neon database.
2. Apply `audit-schema/postgres.sql`.
3. Use a runtime role with insert permissions only where practical.
4. Run `/api/run-demo-incident` and confirm exactly one `infraops_audit.audit_events` row is inserted.
5. Keep production-impacting actions blocked.

The Neon dependency is isolated to the hosted Pages Function adapter. Core packet generation remains provider-neutral in `assets/demo-engine.mjs`.

## Neon Now, RDS Later

Use Neon first when the goal is a polished live evaluation:

- No VPS to maintain.
- No public RDS endpoint.
- No RDS idle-running cost.
- Easy to connect from a lightweight hosted API.
- Real Postgres semantics for the audit schema.

Move to RDS when the goal changes to production deployment:

- Buyer wants AWS-native hosting.
- Incident data must stay inside an AWS account or VPC.
- Private database networking is required.
- KMS, AWS Backup, CloudWatch, security groups, and IAM-based operations matter.
- A paid pilot justifies the additional cost and operational work.

## Adapter Boundary

The product should expose one audit storage interface:

```text
recordAuditEvent(event)
recordIncidentSnapshot(snapshot)
recordAgentRun(run)
recordApprovalRequest(request)
listAuditEvents(incidentId)
```

Implementations can target:

- local Postgres over `psql` for scripts,
- Neon Postgres for the hosted demo,
- RDS PostgreSQL from an AWS-hosted API service,
- Cloudflare Hyperdrive plus Postgres for a Cloudflare-hosted API.

The rest of the application should not know which provider is behind `DATABASE_URL`.

## Cutover Shape

A Neon-to-RDS cutover should be a deployment change, not a rewrite:

1. Provision RDS PostgreSQL.
2. Apply `audit-schema/postgres.sql` and future migrations.
3. Export Neon data with `pg_dump`.
4. Import into RDS with `psql` or `pg_restore`.
5. Change `DATABASE_URL`.
6. Run the demo smoke test and audit insert check.
7. Switch production traffic.
8. Keep Neon read-only until the rollback window closes.

For a small MVP database, the technical cutover should be measured in hours, not days, if provider-specific features are avoided.

## What Not To Do Yet

- Do not use RDS Proxy for the MVP.
- Do not add NAT Gateway just to reach RDS.
- Do not use Multi-AZ until availability requirements justify the spend.
- Do not use OpenSearch for incident evidence search yet.
- Do not introduce a second database for the demo.
- Do not call the storage layer "Neon" in product code.

## Buyer-Safe Explanation

Use this wording in demos:

> The evaluation build uses standard Postgres for audit storage. The hosted demo can run on a low-cost Postgres provider, and the same schema can move to AWS RDS for production when private networking and AWS-native controls are required.
