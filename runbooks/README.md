# Runbooks

Runbooks are written for safe human-led operations. The MVP examples include read-only diagnostics, approval checkpoints, rollback considerations, and audit expectations.

Runbook status labels:

- `read_only`: Safe to perform without approval.
- `approval_required`: Requires human approval before execution.
- `blocked`: Not allowed in this MVP.

No runbook in this scaffold authorizes autonomous production change.
