#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATABASE_URL="${DATABASE_URL:-postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub}"

case "$DATABASE_URL" in
  *localhost*|*127.0.0.1*|*postgres:5432*)
    ;;
  *)
    echo "Refusing to apply schema to a non-local database URL." >&2
    exit 2
    ;;
esac

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required to apply the audit schema." >&2
  exit 1
fi

echo "Applying audit schema to local Postgres only."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f audit-schema/postgres.sql
echo "Audit schema applied."
