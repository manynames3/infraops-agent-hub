# AWS RDS Migration Path

This runbook describes how InfraOps Agent Hub can move from a low-cost hosted Postgres demo database to AWS RDS PostgreSQL without changing product behavior.

The goal is a controlled production migration, not an early overbuild.

## When To Migrate

Move to RDS only when at least one is true:

- A paid pilot requires AWS-native hosting.
- Incident data must stay in an AWS account or VPC.
- Private database networking is required.
- The buyer expects AWS backups, monitoring, KMS, and security group controls.
- The project needs a production architecture story beyond the hosted demo.

Stay on Neon or local Postgres while the goal is sales validation and demo polish.

## Recommended Small Production Shape

Start with the smallest credible RDS deployment:

```text
RDS PostgreSQL
Single-AZ
Small burstable instance class
20 GB gp3 storage
Private subnet
No public database endpoint
Encryption at rest enabled
Automated backups enabled
Deletion protection enabled after validation
```

Avoid for now:

- Multi-AZ,
- read replicas,
- RDS Proxy,
- NAT Gateway,
- ALB,
- ECS/Fargate,
- OpenSearch.

Those are production options, not MVP defaults.

## Migration Checklist

1. Freeze schema changes during the migration window.
2. Confirm the app uses only `DATABASE_URL`.
3. Create the RDS PostgreSQL instance.
4. Apply security groups so only the app runtime can reach RDS.
5. Apply `audit-schema/postgres.sql`.
6. Export the current database:

   ```bash
   pg_dump "$SOURCE_DATABASE_URL" > infraops-audit-export.sql
   ```

7. Import into RDS:

   ```bash
   psql "$RDS_DATABASE_URL" < infraops-audit-export.sql
   ```

8. Run a smoke insert into `infraops_audit.audit_events`.
9. Change the app secret from the source `DATABASE_URL` to `RDS_DATABASE_URL`.
10. Run the hosted demo or local demo against the RDS-backed environment.
11. Keep the old database read-only until the rollback window closes.

## Smoke Test

Use a read-only query first:

```sql
select count(*) from infraops_audit.audit_events;
```

Then insert one demo audit event through the application path, not by hand. The production smoke test should prove that the app can:

- generate an incident packet,
- classify actions correctly,
- write one audit event,
- block approval-required production actions.

## Rollback Plan

If the app fails after cutover:

1. Restore the previous `DATABASE_URL`.
2. Redeploy the previous known-good version.
3. Keep the RDS instance available for inspection.
4. Compare audit event counts and recent records.
5. Retry only after the failed migration step is understood.

Do not run destructive database cleanup during the rollback window.

## Cloudflare And RDS Note

Cloudflare Pages Functions should not connect directly to a private RDS instance without a deliberate network design. For production AWS deployment, prefer one of these:

- host the app/API in AWS near RDS,
- use Cloudflare Hyperdrive deliberately,
- keep Cloudflare for static marketing pages and move the authenticated product API into AWS.

This is why the current demo can use Neon while the production deployment guide keeps AWS RDS as the stronger long-term target.
