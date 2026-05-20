#!/usr/bin/env bash
set -euo pipefail

ACTION_CLASS="${1:-}"
APPROVAL_ID="${2:-}"

usage() {
  echo "Usage: $0 <read_only|approval_required|blocked> [approval_id]" >&2
}

if [[ -z "$ACTION_CLASS" ]]; then
  usage
  exit 64
fi

case "$ACTION_CLASS" in
  read_only)
    echo "Allowed: read-only action may proceed in mock/local mode."
    ;;
  approval_required)
    if [[ -z "$APPROVAL_ID" ]]; then
      echo "Blocked: human approval is required before this action can proceed." >&2
      exit 2
    fi
    echo "Approval recorded: $APPROVAL_ID"
    echo "Dry-run only: this scaffold does not execute production-impacting actions."
    ;;
  blocked)
    echo "Blocked: this action class is not allowed in the MVP scaffold." >&2
    exit 3
    ;;
  *)
    usage
    exit 64
    ;;
esac
