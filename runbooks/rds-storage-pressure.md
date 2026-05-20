# RDS Storage Pressure Runbook

## Scenario

An RDS instance or cluster reports low free storage or rapid storage growth.

## Read-Only Diagnostics

1. Confirm database identifier, engine, environment, and free storage trend.
2. Check whether storage autoscaling is enabled.
3. Inspect top table growth from approved read-only telemetry.
4. Review recent migration or batch job activity.
5. Estimate time to exhaustion from current growth rate.

## Likely Causes

- Large migration or backfill.
- Unbounded audit, event, or job table growth.
- Temporary table spillover.
- Increased write traffic.
- Backup or replication configuration issue.

## Approval-Required Actions

- Increase allocated storage.
- Enable or modify storage autoscaling.
- Stop or pause a batch job.
- Change retention settings.
- Run cleanup or archival operations.

## Blocked Actions

- Dropping tables.
- Truncating production data.
- Deleting backups.
- Changing retention without data owner approval.

## Audit Evidence

Capture storage metrics, projected exhaustion time, candidate tables, proposed action, approval ID, and final storage state.
