CREATE TABLE IF NOT EXISTS incident_audit_log (
    id SERIAL PRIMARY KEY,
    incident_id TEXT NOT NULL,
    service_name TEXT NOT NULL,
    environment TEXT NOT NULL,
    region TEXT,
    alert_type TEXT NOT NULL,
    severity TEXT,
    alert_payload JSONB NOT NULL,
    triage_output JSONB,
    release_correlation_output JSONB,
    runbook_output JSONB,
    action_plan JSONB,
    approval_required BOOLEAN DEFAULT FALSE,
    approval_status TEXT,
    approved_by TEXT,
    action_taken TEXT,
    ticket_url TEXT,
    slack_message_url TEXT,
    postmortem_draft TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_incident_audit_log_incident_id
ON incident_audit_log (incident_id);

CREATE INDEX IF NOT EXISTS idx_incident_audit_log_service_name
ON incident_audit_log (service_name);

CREATE INDEX IF NOT EXISTS idx_incident_audit_log_created_at
ON incident_audit_log (created_at);
