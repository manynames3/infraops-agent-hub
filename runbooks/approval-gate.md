# Approval Gate Runbook

## Goal

Ensure production-impacting actions are reviewed and approved by a human before execution.

## Action Classification

`read_only`:

- Inspect metrics.
- Read logs.
- Summarize incidents.
- Draft a plan.

`approval_required`:

- Scale service capacity.
- Restart workloads.
- Change feature flags.
- Roll back a deploy.
- Create or modify infrastructure.
- Send Slack, email, or status page updates.

`blocked`:

- Delete production data.
- Rotate or expose secrets without a formal break-glass process.
- Disable monitoring.
- Bypass access controls.
- Execute unclear commands.

## Required Approval Fields

- Incident ID.
- Proposed action.
- Environment.
- Expected impact.
- Risk summary.
- Rollback plan.
- Approver identity.
- Expiration time.

## Audit Events

Record both the approval request and the decision. Expired, rejected, and withdrawn approvals must also be recorded.
