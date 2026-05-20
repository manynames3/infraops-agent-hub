#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INPUT_PATH="${1:-sample-alerts/cloudwatch-high-cpu.json}"

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Sample alert not found: $INPUT_PATH" >&2
  exit 1
fi

python3 - "$INPUT_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
alert = json.loads(path.read_text(encoding="utf-8"))
summary = alert.get("summary", "")
severity = alert.get("severity", "unknown")
environment = alert.get("environment", "unknown")
service = alert.get("service", "unknown")
runbook = alert.get("labels", {}).get("runbook", "runbooks/incident-triage.md")

if "CPU" in summary or "cpu" in summary:
    likely_cause = "Sustained compute saturation or traffic increase."
elif "Storage" in summary or "storage" in summary:
    likely_cause = "Storage consumption is increasing faster than expected."
else:
    likely_cause = "Condition requires operator review with additional context."

approval_required_for = []
if environment == "production":
    approval_required_for.append("Any remediation that changes production state.")
else:
    approval_required_for.append("Any action that changes shared infrastructure or external communication.")

result = {
    "alert_id": alert.get("alert_id"),
    "triage_mode": "mock",
    "service": service,
    "environment": environment,
    "severity": severity,
    "impact_assessment": "Potential service degradation. Confirm with read-only metrics and logs.",
    "likely_causes": [
        {
            "cause": likely_cause,
            "confidence": "medium",
            "evidence": [summary]
        }
    ],
    "recommended_runbook": runbook,
    "safe_next_steps": [
        "Review read-only metrics for the affected time window.",
        "Inspect sample logs for correlated errors.",
        "Check recent deployment or configuration changes.",
        "Prepare a human approval request before remediation."
    ],
    "approval_required_for": approval_required_for,
    "audit_note": "Mock triage only. No external APIs were called and no infrastructure was changed."
}

print(json.dumps(result, indent=2, sort_keys=True))
PY
