# Incident Triage Runbook

## Goal

Establish severity, impact, likely cause, and the safest next step without changing production state.

## Read-Only Steps

1. Confirm alert source, service, environment, timestamp, and severity.
2. Check whether the service is customer-facing.
3. Compare the alert with recent logs and deployments.
4. Identify the most relevant service-specific runbook.
5. Record evidence and confidence level.

## Approval Checkpoint

Human approval is required before:

- Scaling services.
- Restarting workloads.
- Rolling back or deploying code.
- Changing infrastructure configuration.
- Changing IAM, networking, database, or secret settings.
- Sending customer-facing updates.

## Stop Conditions

- Alert data is ambiguous or contradictory.
- The proposed action could affect production state and no approval exists.
- The action could delete, overwrite, or expose data.

## Audit Events

Record:

- `alert.received`
- `triage.started`
- `triage.recommendation.created`
- `approval.requested` when applicable
- `triage.closed`
