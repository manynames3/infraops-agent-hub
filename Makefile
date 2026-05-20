.PHONY: help validate up demo down logs schema audit-tail

help:
	@echo "InfraOps Agent Hub commands"
	@echo "  make validate   Validate JSON, scripts, and secret patterns"
	@echo "  make up         Start local Postgres and n8n with Docker Compose"
	@echo "  make demo       Run the local mock incident demo"
	@echo "  make down       Stop local Docker Compose services"
	@echo "  make logs       Tail local Docker Compose logs"
	@echo "  make schema     Apply audit schema to local Postgres"
	@echo "  make audit-tail Show recent local audit events"

validate:
	./scripts/validate-scaffold.sh

up:
	./scripts/bootstrap-local.sh

demo:
	./scripts/run-local-demo.sh

down:
	docker compose down

logs:
	docker compose logs --tail=100 -f

schema:
	./scripts/apply-audit-schema-local.sh

audit-tail:
	psql "$${DATABASE_URL:-postgres://infraops:local_infraops_password_do_not_use_in_prod@localhost:5432/infraops_hub}" \
		-c "select recorded_at, incident_id, event_type, summary from infraops_audit.audit_events order by recorded_at desc limit 10;"
