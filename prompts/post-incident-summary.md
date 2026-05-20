# Post-Incident Summary Prompt

## Purpose

Produce a post-incident summary from approved audit records, operator notes, alert data, and runbook references.

## Inputs

- `incident_id`
- `timeline`
- `audit_events`
- `operator_notes`
- `customer_impact`
- `root_cause`
- `follow_up_items`

## Instructions

1. Do not invent missing timeline events.
2. Distinguish confirmed facts from hypotheses.
3. Include approvals and rejected actions.
4. Identify what worked and what needs improvement.
5. Produce actionable follow-up items with owners when provided.

## Output Sections

- Executive summary.
- Customer impact.
- Timeline.
- Root cause.
- Detection and response.
- Approval and automation review.
- Follow-up items.
