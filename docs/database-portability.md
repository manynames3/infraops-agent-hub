# Database Portability

InfraOps Agent Hub should treat Postgres as a portable hosted-demo audit store, not as a commitment to one production persistence provider.

The near-term hosted demo can use Neon because it is cheap, simple, and speaks standard Postgres. Production AWS governance deployments may still prefer AWS-native storage patterns when private networking, IAM integration, compliance posture, and operational controls matter more than demo idling cost.

Suggested positioning:

> Neon is optional for hosted demos that need persistent Postgres-backed audit or workflow data without paying for always-on database infrastructure. For production AWS governance deployments, AWS-native storage may still be preferred when private networking, IAM integration, compliance posture, and operational controls matter more than demo idling cost.

## Decision

Use standard PostgreSQL with one runtime connection string for hosted demo persistence:

```text
DATABASE_URL=postgres://...
```

Do not bind core packet-generation logic to a Neon SDK, Supabase client, Cloudflare D1, DynamoDB, or provider-specific database feature. The hosted demo can use a Neon adapter, but the product should talk through a small audit-store boundary.

For local and hosted Postgres targets, that adapter executes standard SQL against `audit-schema/postgres.sql`. For production AWS governance workloads, a separate AWS-native adapter may be the right architecture if the buyer needs IAM-native authorization, private account deployment, retention controls, and operational audit integration.

## Supported Targets

| Target | Use case | Why |
| --- | --- | --- |
| Local Docker Postgres | Local development and interviews | Matches the repository demo and is easy to reset. |
| Neon Postgres | Optional hosted evaluation demo and early paid pilot | Real Postgres with low idle cost and minimal operations. |
| AWS RDS PostgreSQL | Production AWS deployment when relational Postgres remains the right store | Private networking, KMS, backups, CloudWatch, and stronger enterprise fit. |
| Aurora PostgreSQL | Later scale option | Only after RDS limits or enterprise availability requirements justify it. |
| AWS-native event/audit storage | Production governance workloads when appropriate | IAM-native controls, account-local deployment, retention controls, CloudTrail/EventBridge/S3/DynamoDB patterns. |

## Portability Rules

- Keep schema changes in SQL migration files.
- Use standard Postgres types where possible.
- Keep `jsonb` for evidence payloads, packet snapshots, and provider-specific metadata.
- Keep runtime configuration in environment variables.
- Do not hardcode hostnames, ports, users, or database names.
- Do not depend on Neon branching, Neon Auth, Supabase Realtime, D1 SQL dialect, RDS-only extensions, or DynamoDB-specific access patterns in core packet-generation logic.
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
DATABASE_URL=postgresql://<user>:<password>@<project>-pooler.<region>.aws.neon.tech/<database>?sslmode=require&channel_binding=require
DATABASE_SSL_MODE=require
ENABLE_HOSTED_AUDIT_WRITES=true
```

The same shape is documented in `.env.example` and `config.example.env`. Keep real values in Cloudflare environment variables or another secret store, never in Git.

SSL handling:

- Neon connection strings should require SSL with `sslmode=require`.
- `channel_binding=require` is acceptable when Neon provides it in the connection string.
- For Cloudflare Pages Functions, prefer Neon's pooled connection string because serverless/edge runtimes can create short-lived connections.
- The current Pages Function uses `@neondatabase/serverless`, passes `DATABASE_URL` directly to `neon(...)`, and refuses hosted Neon writes if `DATABASE_URL` does not include `sslmode=require`.
- Local Docker Compose Postgres should keep `DATABASE_SSL_MODE=disable`.

Before enabling writes:

1. Create the Neon project and database.
2. Copy the pooled connection string from Neon.
3. Confirm the connection string includes `sslmode=require`; keep `channel_binding=require` if Neon includes it.
4. Store the connection string as `DATABASE_URL` in Cloudflare Pages environment variables.
5. Set `DATABASE_PROVIDER=neon`.
6. Keep `ENABLE_HOSTED_AUDIT_WRITES=false` until schema initialization is complete.
7. Apply `audit-schema/postgres.sql` to Neon.
8. Set `ENABLE_HOSTED_AUDIT_WRITES=true`.
9. Run `/api/run-demo-incident` and confirm exactly one `infraops_audit.audit_events` row is inserted.
10. Keep production-impacting actions blocked.

Schema initialization:

```bash
psql "$DATABASE_URL" -f audit-schema/postgres.sql
```

Verification query:

```bash
psql "$DATABASE_URL" -c "select recorded_at, incident_id, event_type, summary from infraops_audit.audit_events order by recorded_at desc limit 5;"
```

The Neon dependency is isolated to the hosted Pages Function adapter. Core packet generation remains provider-neutral in `assets/demo-engine.mjs`.

## Idle-Cost Tradeoffs

Local Docker Postgres:

- Best for development.
- Costs nothing beyond the local machine.
- Not suitable as a hosted public demo database.

Neon:

- Best for hosted demos that need persistent Postgres data.
- Avoids paying for an always-on database just to keep a portfolio demo alive.
- Has serverless/edge-friendly connection options.
- Adds a third-party managed Postgres dependency.

AWS RDS or Aurora PostgreSQL:

- Stronger AWS production story when relational Postgres remains appropriate.
- Usually has meaningful idle-running cost because the database instance is provisioned.
- Better fit when private networking, AWS backup/monitoring, and account-local controls matter.

AWS-native event/audit storage:

- Better production governance story when the system should behave like an AWS-native control plane.
- May use DynamoDB for event records, S3 for durable evidence snapshots, EventBridge for event flow, and CloudTrail/KMS/IAM for governance.
- More work than the hosted demo needs and should be introduced behind an adapter boundary.

## Neon Now, AWS Later

Use Neon first when the goal is a polished live evaluation:

- No VPS to maintain.
- No public RDS endpoint.
- No RDS idle-running cost.
- Easy to connect from a lightweight hosted API.
- Real Postgres semantics for the audit schema.

Move to AWS-native production storage when the goal changes to governance-grade deployment:

- Buyer wants AWS-native hosting.
- Incident data must stay inside an AWS account or VPC.
- Private database networking is required.
- KMS, AWS Backup, CloudWatch, security groups, and IAM-based operations matter.
- A paid pilot justifies the additional cost and operational work.
- DynamoDB/S3/EventBridge/CloudTrail patterns tell a stronger governance story than a third-party hosted database.

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
- DynamoDB/S3/EventBridge from an AWS-native governance API,
- Cloudflare Hyperdrive plus Postgres for a Cloudflare-hosted API.

The rest of the application should not know which provider is behind `DATABASE_URL`.

## Neon To RDS Cutover Shape

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

For a move from Postgres to DynamoDB or another AWS-native event store, treat it as an adapter migration rather than a direct database cutover. Preserve the incident packet and audit-event contract, then map records into the AWS-native table/object/event model.

## What Not To Do Yet

- Do not use RDS Proxy for the MVP.
- Do not add NAT Gateway just to reach RDS.
- Do not use Multi-AZ until availability requirements justify the spend.
- Do not use OpenSearch for incident evidence search yet.
- Do not introduce a second database for the demo.
- Do not call the storage layer "Neon" in product code.
- Do not rewrite the hosted demo around DynamoDB before there is a production governance requirement.

## Buyer-Safe Explanation

Use this wording in demos:

> The evaluation build can use standard Postgres for audit storage. Neon is optional for hosted demos that need persistent data without an always-on database bill. For production AWS governance deployments, AWS-native storage may still be preferred when private networking, IAM integration, compliance posture, and operational controls matter more than demo idling cost.
