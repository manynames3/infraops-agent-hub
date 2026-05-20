# Incident Triage Prompt

## Purpose

Classify an incoming alert, identify likely impact, map the alert to a runbook, and propose safe next steps.

## Inputs

- `alert_id`
- `source`
- `service`
- `environment`
- `severity`
- `summary`
- `metric_context`
- `log_excerpt`
- `recent_changes`
- `known_runbooks`

## Instructions

1. Summarize the alert in plain language.
2. Identify whether the environment appears production-like.
3. List evidence from the alert and logs.
4. Identify likely causes and confidence level.
5. Select the most relevant runbook.
6. Recommend read-only diagnostics first.
7. Mark any remediation as requiring human approval.
8. Produce an audit note with input references.

## Output Format

```json
{
  "alert_id": "<id>",
  "triage_mode": "mock",
  "severity": "<severity>",
  "impact_assessment": "<short assessment>",
  "likely_causes": [
    {
      "cause": "<cause>",
      "confidence": "low|medium|high",
      "evidence": ["<evidence item>"]
    }
  ],
  "recommended_runbook": "<path>",
  "safe_next_steps": ["<read-only step>"],
  "approval_required_for": ["<action>"],
  "audit_note": "<note>"
}
```
