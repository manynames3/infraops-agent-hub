# High 5xx Error Rate Runbook

## Scenario

An HTTP service is returning elevated 5xx responses across one or more critical routes.

## Read-Only Diagnostics

1. Confirm the alert window, affected service, environment, and customer-facing routes.
2. Compare 5xx rate against request volume to avoid overreacting to low traffic.
3. Review recent release events, configuration changes, and dependency incidents.
4. Inspect error logs for repeated status codes, timeout patterns, and route concentration.
5. Check whether errors started after a release or dependency change.

## Likely Causes

- Upstream dependency timeout.
- Recent release changed request behavior.
- Exhausted worker pool or queue.
- Bad configuration or missing environment variable.
- Retry storm from a downstream process.

## Safe Next Steps

- Keep diagnostics read-only until a human approves remediation.
- Capture representative request IDs and affected routes.
- Prepare an approval request if rollback, restart, scaling, or config changes are proposed.
- Document customer impact and uncertainty clearly.

## Approval-Required Actions

- Roll back a release.
- Restart workloads.
- Scale service capacity.
- Change timeout, retry, queue, or rate-limit configuration.
- Send customer-facing status updates.

## Stop Conditions

- The error source is unclear.
- The proposed action affects production or shared infrastructure and has no approval.
- The action could hide evidence needed for incident review.

## Audit Evidence

Record alert ID, incident ID, runbook path, release correlation, sampled request IDs, planned next steps, approval status, and final summary.
