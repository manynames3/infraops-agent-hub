# Approval Request Prompt

## Purpose

Prepare a concise approval request for a human operator before any production-impacting action.

## Inputs

- `incident_id`
- `service`
- `environment`
- `proposed_action`
- `reason`
- `risk`
- `rollback_plan`
- `expected_customer_impact`
- `time_limit`
- `approver_group`

## Instructions

1. State the proposed action in one sentence.
2. Explain why the action is needed.
3. Identify customer, data, cost, and availability risk.
4. Include a rollback plan.
5. Include the expiration time for the approval.
6. Make it clear that no action will run until approval is granted.

## Output Format

```json
{
  "approval_required": true,
  "approval_type": "production-impacting-change",
  "incident_id": "<incident id>",
  "proposed_action": "<action>",
  "reason": "<reason>",
  "risk_summary": "<risk>",
  "rollback_plan": "<rollback plan>",
  "approval_expiration": "<timestamp>",
  "status": "pending_human_approval"
}
```
