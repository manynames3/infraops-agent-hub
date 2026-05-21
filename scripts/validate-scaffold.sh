#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Validating JSON files."
python3 - <<'PY'
import json
from pathlib import Path

ignored_dirs = {".git", "node_modules", ".wrangler"}
json_files = sorted(path for path in Path(".").glob("**/*.json") if not ignored_dirs.intersection(path.parts))
for path in json_files:
    with path.open("r", encoding="utf-8") as handle:
        json.load(handle)
    print(f"  ok {path}")
PY

echo "Validating shell syntax."
while IFS= read -r script_path; do
  bash -n "$script_path"
  if ! grep -q "set -euo pipefail" "$script_path"; then
    echo "Missing set -euo pipefail in $script_path" >&2
    exit 1
  fi
  echo "  ok $script_path"
done < <(find scripts -type f -name "*.sh" | sort)

echo "Validating hosted demo engine."
if command -v node >/dev/null 2>&1; then
  node scripts/validate-demo-engine.mjs
else
  echo "  skipped hosted demo engine validation because node is not installed"
fi

echo "Checking Docker Compose configuration when available."
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose -f docker-compose.yml config >/dev/null
  echo "  ok docker compose config"
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose -f docker-compose.yml config >/dev/null
  echo "  ok docker-compose config"
else
  echo "  skipped Docker Compose validation because Compose is not installed"
fi

echo "Checking for obvious committed secret patterns."
if grep -R -E "(AKIA[0-9A-Z]{16}|xox[baprs]-|ghp_[A-Za-z0-9_]{36,}|sk-[A-Za-z0-9]{20,})" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.wrangler >/tmp/infraops-secret-scan.txt; then
  cat /tmp/infraops-secret-scan.txt >&2
  echo "Potential secret pattern found." >&2
  exit 1
fi

echo "Validation passed."
