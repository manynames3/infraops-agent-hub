# Audit Logging

## Goals

The audit model should answer:

- What alert or incident was handled?
- What evidence was reviewed?
- What did the agent recommend?
- Which actions were blocked?
- Which approvals were requested?
- Who approved or rejected a production-impacting action?
- What changed after human action?

## Tables

- `infraops_audit.agent_runs`: One row per agent execution.
- `infraops_audit.approval_requests`: Human approval lifecycle.
- `infraops_audit.tool_invocations`: Intended tool calls and blocked or completed outcomes.
- `infraops_audit.audit_events`: Append-style event stream for review.
- `infraops_audit.incident_snapshots`: Captured alert state at a point in time.

## Event Naming

Use dotted event names:

- `alert.received`
- `triage.started`
- `triage.recommendation.created`
- `approval.requested`
- `approval.decided`
- `tool.invocation.blocked`
- `incident.closed`

## Data Hygiene

- Store references to logs where possible instead of raw sensitive logs.
- Redact secrets before writing prompt inputs or model outputs.
- Keep approval decisions immutable.
- Avoid storing customer personal data in audit evidence.
