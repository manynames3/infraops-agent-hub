# Post-Incident Review Runbook

## Goal

Turn incident records into a factual review and concrete follow-up work.

## Inputs

- Alert payloads.
- Triage output.
- Audit events.
- Approval requests and decisions.
- Operator notes.
- Customer impact statement.

## Process

1. Build a timeline from audit records.
2. Separate confirmed facts from hypotheses.
3. Identify detection, diagnosis, approval, and remediation delays.
4. Capture what was automated and what remained manual.
5. Create follow-up items with owners and due dates when available.

## Safety Review Questions

- Did any action run without approval?
- Were any secrets or customer data exposed in prompts or logs?
- Were read-only and production-impacting actions clearly separated?
- Did audit records preserve enough context for review?

## Outputs

- Incident summary.
- Timeline.
- Root cause.
- Impact.
- Follow-up items.
- Automation safety notes.
