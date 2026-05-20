#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALERT_PATH="sample-alerts/invoicebridge-5xx-alert.json"
LOG_PATH="sample-logs/invoicebridge-errors.json"
RUNBOOK_PATH="runbooks/high-5xx-error-rate.md"
SCHEMA_PATH="audit-schema/postgres.sql"

DATABASE_URL="${DATABASE_URL:-postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub}"
POSTGRES_USER="${POSTGRES_USER:-infraops}"
POSTGRES_DB="${POSTGRES_DB:-infraops_hub}"

for flag in ENABLE_REAL_AWS_CALLS ENABLE_REAL_GITHUB_CALLS ENABLE_REAL_SLACK_CALLS ENABLE_REAL_LLM_CALLS; do
  if [[ "${!flag:-false}" == "true" ]]; then
    echo "Refusing to run local demo because $flag is true. This demo is mock-only." >&2
    exit 2
  fi
done

if [[ "${INFRAOPS_INTEGRATION_MODE:-mock}" != "mock" ]]; then
  echo "Refusing to run local demo unless INFRAOPS_INTEGRATION_MODE=mock." >&2
  exit 2
fi

case "$DATABASE_URL" in
  *localhost*|*127.0.0.1*|*postgres:5432*)
    ;;
  *)
    echo "Refusing to insert audit data into a non-local database URL." >&2
    exit 2
    ;;
esac

for required_file in "$ALERT_PATH" "$LOG_PATH" "$RUNBOOK_PATH" "$SCHEMA_PATH"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required demo file is missing: $required_file" >&2
    exit 1
  fi
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to run the local demo." >&2
  exit 1
fi

use_host_psql=false
use_container_psql=false

if command -v psql >/dev/null 2>&1 && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "select 1;" >/dev/null 2>&1; then
  use_host_psql=true
elif command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -qx 'infraops-postgres'; then
  use_container_psql=true
else
  echo "Local Postgres is not reachable." >&2
  echo "Start it with: ./scripts/bootstrap-local.sh" >&2
  echo "Then rerun: ./scripts/run-local-demo.sh" >&2
  exit 1
fi

DEMO_JSON="$(python3 - "$ALERT_PATH" "$LOG_PATH" "$RUNBOOK_PATH" <<'PY'
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

alert_path = Path(sys.argv[1])
log_path = Path(sys.argv[2])
runbook_path = Path(sys.argv[3])

alert = json.loads(alert_path.read_text(encoding="utf-8"))
logs = json.loads(log_path.read_text(encoding="utf-8"))
runbook = runbook_path.read_text(encoding="utf-8")

entries = logs.get("entries", [])
error_entries = [entry for entry in entries if int(entry.get("status", 0)) >= 500]
status_counts = Counter(str(entry.get("status")) for entry in error_entries)
route_counts = Counter(entry.get("route", "unknown") for entry in error_entries)
release_counts = Counter(entry.get("release", "unknown") for entry in error_entries)
release_events = logs.get("release_events", [])

dominant_route = route_counts.most_common(1)[0][0] if route_counts else "unknown"
dominant_release = release_counts.most_common(1)[0][0] if release_counts else "unknown"
request_ids = [entry.get("request_id") for entry in error_entries[:4] if entry.get("request_id")]

release_event = release_events[0] if release_events else {}
release_summary = "No release event was present in the sample logs."
release_confidence = "low"
if release_event and dominant_release == release_event.get("release"):
    release_summary = (
        f"Errors are concentrated on {dominant_release}, deployed at "
        f"{release_event.get('timestamp')} with commit {release_event.get('commit')}."
    )
    release_confidence = "medium"

runbook_matches = []
for keyword in ["5xx", "timeout", "release", "rollback", "customer-facing"]:
    if keyword.lower() in runbook.lower():
        runbook_matches.append(keyword)

triage = {
    "stage": "triage",
    "mode": "mock",
    "severity": alert.get("severity"),
    "impact": alert.get("labels", {}).get("customer_impact"),
    "finding": (
        f"{alert.get('service')} is above the configured 5xx threshold with "
        f"{alert.get('metric_context', {}).get('error_rate_percent')} percent errors."
    ),
    "evidence": [
        alert.get("summary"),
        f"{len(error_entries)} sampled 5xx log entries in {logs.get('time_window', {}).get('start')} to {logs.get('time_window', {}).get('end')}.",
        f"Dominant affected route: {dominant_route}."
    ]
}

release_correlation = {
    "stage": "release_correlation",
    "mode": "mock",
    "finding": release_summary,
    "confidence": release_confidence,
    "release_event": release_event,
    "status_counts": dict(status_counts),
    "sample_request_ids": request_ids
}

runbook_lookup = {
    "stage": "runbook_lookup",
    "mode": "mock",
    "selected_runbook": str(runbook_path),
    "matched_terms": runbook_matches,
    "reason": "The alert and log evidence indicate elevated HTTP 5xx responses after a recent release."
}

next_step_plan = {
    "stage": "next_step_planning",
    "mode": "mock",
    "read_only_steps": [
        "Review route-level 5xx rate for /v1/invoices/render and /v1/webhooks/deliver.",
        "Compare errors before and after invoicebridge-api@2026.05.20.3.",
        "Inspect renderer timeout metrics and queue depth using approved read-only telemetry.",
        "Prepare an approval request before rollback, restart, scaling, or config changes."
    ],
    "approval_required_steps": [
        "Rollback invoicebridge-api@2026.05.20.3.",
        "Change renderer timeout or retry settings.",
        "Restart invoicebridge-api workloads.",
        "Send customer-facing incident communications."
    ],
    "blocked_steps": [
        "No production mutation is allowed from this local demo."
    ]
}

documentation = {
    "stage": "documentation",
    "mode": "mock",
    "incident_note": (
        f"InvoiceBridge is experiencing elevated 5xx responses in {alert.get('environment')}. "
        f"Errors are concentrated on {dominant_route}; release correlation is {release_confidence}."
    ),
    "operator_handoff": (
        "Continue read-only diagnosis and request human approval before any rollback, restart, "
        "scaling, configuration change, or external communication."
    )
}

audit_summary = (
    f"Mock triage for {alert.get('incident_id')} identified elevated 5xx responses on "
    f"{alert.get('service')} and selected {runbook_path}."
)

final_summary = {
    "incident_id": alert.get("incident_id"),
    "service": alert.get("service"),
    "environment": alert.get("environment"),
    "severity": alert.get("severity"),
    "status": "human_review_required",
    "summary": audit_summary,
    "likely_cause": "Recent release changed renderer timeout or webhook retry behavior; mock confidence is medium.",
    "recommended_next_step": "Continue read-only checks and draft a human approval request for any rollback or config change.",
    "approval_required": True
}

demo = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "source_files": {
        "alert": str(alert_path),
        "logs": str(log_path),
        "runbook": str(runbook_path)
    },
    "incident_id": alert.get("incident_id"),
    "audit_summary": audit_summary,
    "outputs": {
        "triage": triage,
        "release_correlation": release_correlation,
        "runbook_lookup": runbook_lookup,
        "next_step_plan": next_step_plan,
        "documentation": documentation
    },
    "final_summary": final_summary,
    "safety": {
        "integration_mode": "mock",
        "external_api_calls": 0,
        "production_changes": 0,
        "human_approval_required": True
    }
}

print(json.dumps(demo, indent=2, sort_keys=True))
PY
)"

incident_id="$(DEMO_JSON="$DEMO_JSON" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["DEMO_JSON"])["incident_id"])
PY
)"

audit_summary="$(DEMO_JSON="$DEMO_JSON" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["DEMO_JSON"])["audit_summary"])
PY
)"

if [[ "$use_host_psql" == "true" ]]; then
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA_PATH" >/dev/null
  audit_record_id="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -At \
    -v incident_id="$incident_id" \
    -v audit_summary="$audit_summary" \
    -v evidence="$DEMO_JSON" \
    -c "INSERT INTO infraops_audit.audit_events (incident_id, event_type, actor, action_class, summary, evidence) VALUES (:'incident_id', 'triage.recommendation.created', 'infraops-agent-hub-local-demo', 'read_only', :'audit_summary', :'evidence'::jsonb) RETURNING id;")"
elif [[ "$use_container_psql" == "true" ]]; then
  docker exec -i infraops-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < "$SCHEMA_PATH" >/dev/null
  audit_record_id="$(docker exec -i infraops-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -At \
    -v incident_id="$incident_id" \
    -v audit_summary="$audit_summary" \
    -v evidence="$DEMO_JSON" \
    -c "INSERT INTO infraops_audit.audit_events (incident_id, event_type, actor, action_class, summary, evidence) VALUES (:'incident_id', 'triage.recommendation.created', 'infraops-agent-hub-local-demo', 'read_only', :'audit_summary', :'evidence'::jsonb) RETURNING id;")"
else
  echo "No usable local Postgres connection was found." >&2
  exit 1
fi

DEMO_JSON="$DEMO_JSON" AUDIT_RECORD_ID="$audit_record_id" python3 - <<'PY'
import json
import os

demo = json.loads(os.environ["DEMO_JSON"])
outputs = demo["outputs"]
summary = demo["final_summary"]

print("InfraOps Agent Hub local mock demo")
print("==================================")
print()
print("Inputs")
for name, path in demo["source_files"].items():
    print(f"- {name}: {path}")
print()
print("Mocked agent outputs")
print(f"- Triage: {outputs['triage']['finding']}")
print(f"- Release correlation: {outputs['release_correlation']['finding']}")
print(f"- Runbook lookup: selected {outputs['runbook_lookup']['selected_runbook']}")
print(f"- Next-step planning: {len(outputs['next_step_plan']['read_only_steps'])} read-only steps, {len(outputs['next_step_plan']['approval_required_steps'])} approval-required steps")
print(f"- Documentation: {outputs['documentation']['incident_note']}")
print()
print(f"Audit record inserted: {os.environ['AUDIT_RECORD_ID']}")
print()
print("Final incident summary")
print(f"- Incident: {summary['incident_id']}")
print(f"- Service: {summary['service']} ({summary['environment']})")
print(f"- Severity: {summary['severity']}")
print(f"- Status: {summary['status']}")
print(f"- Likely cause: {summary['likely_cause']}")
print(f"- Recommended next step: {summary['recommended_next_step']}")
print("- Safety: mock-only, no external API calls, no production changes")
PY
