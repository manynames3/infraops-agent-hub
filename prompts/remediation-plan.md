# Remediation Plan Prompt

## Purpose

Draft a safe remediation plan after triage has identified a likely cause.

## Inputs

- `incident_id`
- `triage_summary`
- `selected_runbook`
- `environment`
- `service`
- `blast_radius`
- `rollback_options`
- `approval_policy`

## Instructions

1. Confirm whether the plan is read-only, approval-required, or blocked.
2. Start with diagnostics that do not change production state.
3. For each production-impacting step, state the exact approval required.
4. Include pre-checks, expected outcome, rollback plan, and stop conditions.
5. Do not produce commands that delete data, revoke broad access, or mutate production without approval.
6. Use placeholders for provider-specific calls.

## Output Sections

- Scope.
- Preconditions.
- Read-only diagnostics.
- Approval-required actions.
- Rollback plan.
- Stop conditions.
- Audit events to record.
