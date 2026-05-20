# ECS CPU Saturation Runbook

## Scenario

An ECS-backed service reports sustained high CPU utilization.

## Read-Only Diagnostics

1. Review CPU, memory, request rate, latency, and error trends.
2. Compare current task count against desired task count.
3. Check recent deployment timestamps.
4. Inspect sample logs for expensive requests, retries, or tight loops.
5. Confirm whether downstream dependency latency increased.

## Likely Causes

- Traffic spike.
- Inefficient code path introduced by a recent deploy.
- Downstream timeout loop.
- Task size too small for current load.
- Batch job or background worker contention.

## Approval-Required Actions

- Increase desired task count.
- Roll back a service deployment.
- Restart tasks.
- Change autoscaling policy.
- Modify task CPU or memory allocation.

## Rollback Considerations

- Scaling up can increase cost.
- Rolling back can reintroduce previous defects.
- Restarting tasks can worsen availability during peak traffic.

## Audit Evidence

Capture alert ID, service name, environment, time window, selected action, approval ID, and observed recovery signal.
