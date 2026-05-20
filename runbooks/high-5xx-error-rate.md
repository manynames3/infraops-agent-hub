# High 5xx Error Rate Runbook

## Common causes

- Recent release regression
- Database connection pool pressure
- Downstream timeout
- Region-specific dependency issue

## First checks

1. Review recent error logs.
2. Review recent releases.
3. Check database connection count.
4. Check downstream service latency.
5. Confirm whether the issue is isolated to one region.

## Safe actions

- Create an incident ticket.
- Notify the operations channel.
- Gather recent logs and metrics.
- Draft a status summary.

## Approval-needed actions

- Roll back the release.
- Restart the affected service.
- Scale service capacity.
- Change runtime configuration.

## Escalation

Escalate to the platform owner if the error rate remains elevated, affects multiple regions, or blocks customer-facing invoice generation.
