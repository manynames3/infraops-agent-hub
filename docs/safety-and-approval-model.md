# Safety and Approval Model

## Default Posture

InfraOps Agent Hub starts in mock mode. The system can inspect sample data, produce recommendations, and draft approval requests. It cannot make live infrastructure changes.

## Action Classes

`read_only`:

- Summarize alerts.
- Parse logs.
- Inspect metrics from approved read-only sources.
- Draft runbook recommendations.

`approval_required`:

- Scale infrastructure.
- Restart services.
- Roll back or deploy applications.
- Modify cloud resources.
- Change permissions, secrets, routing, networking, or database settings.
- Send external communications.

`blocked`:

- Delete production data.
- Disable monitoring.
- Exfiltrate secrets.
- Bypass identity controls.
- Execute ambiguous commands.

## Approval Requirements

An approval must include:

- Incident ID.
- Proposed action.
- Environment.
- Risk summary.
- Rollback plan.
- Approver identity.
- Expiration time.

Approval must be recorded before a production-impacting action can be prepared for execution. This MVP never executes the action, even when an approval ID is supplied to a script.

## Future Enforcement Points

Future implementation should enforce approval at:

- Prompt policy.
- Workflow nodes.
- API adapter methods.
- Database constraints.
- Test fixtures.
- Deployment configuration.
