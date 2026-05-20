-- InfraOps Agent Hub audit schema.
-- Safe local schema setup only. This file does not remove existing data.

CREATE SCHEMA IF NOT EXISTS infraops_audit;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  CREATE TYPE infraops_audit.action_class AS ENUM ('read_only', 'approval_required', 'blocked');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE TYPE infraops_audit.approval_status AS ENUM ('pending', 'approved', 'rejected', 'expired', 'withdrawn');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE TYPE infraops_audit.audit_event_type AS ENUM (
    'alert.received',
    'triage.started',
    'triage.recommendation.created',
    'approval.requested',
    'approval.decided',
    'tool.invocation.requested',
    'tool.invocation.blocked',
    'tool.invocation.completed',
    'incident.snapshot.created',
    'incident.closed'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS infraops_audit.agent_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id text NOT NULL,
  run_mode text NOT NULL DEFAULT 'mock',
  agent_name text NOT NULL DEFAULT 'infraops-agent-hub',
  model_provider text NOT NULL DEFAULT 'mock',
  model_name text NOT NULL DEFAULT 'mock-triage-model',
  prompt_version text NOT NULL DEFAULT 'local-scaffold',
  input_fingerprint text,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  created_by text NOT NULL DEFAULT 'local-operator',
  CONSTRAINT agent_runs_mode_check CHECK (run_mode IN ('mock', 'dry_run', 'read_only'))
);

CREATE TABLE IF NOT EXISTS infraops_audit.approval_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id text NOT NULL,
  agent_run_id uuid REFERENCES infraops_audit.agent_runs(id),
  action_class infraops_audit.action_class NOT NULL DEFAULT 'approval_required',
  proposed_action text NOT NULL,
  reason text NOT NULL,
  risk_summary text NOT NULL,
  rollback_plan text NOT NULL,
  environment text NOT NULL,
  status infraops_audit.approval_status NOT NULL DEFAULT 'pending',
  requested_by text NOT NULL DEFAULT 'infraops-agent-hub',
  decided_by text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz,
  expires_at timestamptz NOT NULL,
  production_apply_allowed boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT approval_requires_human_decision CHECK (
    status <> 'approved'
    OR (decided_by IS NOT NULL AND decided_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS infraops_audit.tool_invocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id text NOT NULL,
  agent_run_id uuid REFERENCES infraops_audit.agent_runs(id),
  approval_request_id uuid REFERENCES infraops_audit.approval_requests(id),
  tool_name text NOT NULL,
  action_class infraops_audit.action_class NOT NULL,
  intent text NOT NULL,
  request_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  response_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  blocked_reason text,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  created_by text NOT NULL DEFAULT 'infraops-agent-hub',
  CONSTRAINT production_actions_need_approval CHECK (
    action_class <> 'approval_required'
    OR approval_request_id IS NOT NULL
  )
);

CREATE TABLE IF NOT EXISTS infraops_audit.audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id text NOT NULL,
  event_type infraops_audit.audit_event_type NOT NULL,
  actor text NOT NULL,
  action_class infraops_audit.action_class NOT NULL DEFAULT 'read_only',
  summary text NOT NULL,
  agent_run_id uuid REFERENCES infraops_audit.agent_runs(id),
  approval_request_id uuid REFERENCES infraops_audit.approval_requests(id),
  tool_invocation_id uuid REFERENCES infraops_audit.tool_invocations(id),
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS infraops_audit.incident_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id text NOT NULL,
  source text NOT NULL,
  service text NOT NULL,
  environment text NOT NULL,
  severity text NOT NULL,
  status text NOT NULL,
  summary text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agent_runs_incident_id
  ON infraops_audit.agent_runs (incident_id);

CREATE INDEX IF NOT EXISTS idx_approval_requests_incident_status
  ON infraops_audit.approval_requests (incident_id, status);

CREATE INDEX IF NOT EXISTS idx_tool_invocations_incident_id
  ON infraops_audit.tool_invocations (incident_id);

CREATE INDEX IF NOT EXISTS idx_audit_events_incident_recorded
  ON infraops_audit.audit_events (incident_id, recorded_at);

CREATE INDEX IF NOT EXISTS idx_incident_snapshots_incident_id
  ON infraops_audit.incident_snapshots (incident_id);
