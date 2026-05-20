# InfraOps Agent Hub

Private AI incident triage for cloud teams that need speed, control, and proof.

InfraOps Agent Hub is a self-hosted agentic AI operations prototype. It uses n8n to coordinate alerts, logs, deployment history, runbooks, Slack updates, ticket creation, approvals, and audit records.

## Pitch

InfraOps Agent Hub turns noisy cloud alerts into evidence-backed, human-approved incident workflows.

## Problem

Cloud teams already have monitoring, logs, GitHub, Slack, tickets, and runbooks. During an incident, engineers still jump across all of them manually to answer what changed, what broke, who should be notified, and what should be documented.

## Solution

When an alert fires, the workflow:

1. Receives the alert through an n8n webhook.
2. Collects relevant logs, metrics, deployment history, and service health data.
3. Searches approved runbooks.
4. Uses specialized AI agents to summarize evidence and recommend next steps.
5. Creates a ticket or issue.
6. Sends a Slack incident summary.
7. Requests human approval before high-risk actions.
8. Saves an audit record.
9. Generates a postmortem draft.

## Core Use Case

The first demo scenario is an invoice API with a high 5xx error rate shortly after a deployment.

## Agents

- Incident Triage Agent: identifies service, severity, evidence, and open questions.
- Deployment Correlation Agent: checks commits, CI runs, and deployment timing.
- Runbook Agent: retrieves approved internal guidance.
- Remediation Planner Agent: proposes safe next steps with evidence.
- Documentation Agent: creates tickets, audit entries, and postmortem drafts.

## MVP Workflow

```text
Webhook Trigger
-> Validate Alert Payload
-> Normalize Incident Context
-> Query Logs and Service Health
-> Query GitHub Commits and Actions
-> Load Matching Runbooks
-> Triage Agent
-> Deployment Correlation Agent
-> Runbook Agent
-> Remediation Planner Agent
-> Approval Gate
-> Create GitHub Issue
-> Insert Audit Record
-> Generate Postmortem Draft
-> Send Final Slack Summary
```

## MVP Integrations

- n8n self-hosted
- AWS CloudWatch
- GitHub API
- GitHub Actions
- Slack
- GitHub Issues
- Postgres
- Markdown runbooks
- OpenAI, Anthropic, or local LLM provider

## Why It Is Defendable

The moat is not the model. The moat is the workflow package around the model:

- Prebuilt incident playbooks
- Evidence-based recommendations
- Human approval gates
- Audit records by default
- Private deployment option
- Reusable runbook and prompt templates

## Local Development

```bash
git clone https://github.com/manynames3/infraops-agent-hub.git
cd infraops-agent-hub
cp .env.example .env
docker compose up -d
```

Open n8n at:

```text
http://localhost:5678
```

Trigger a sample alert:

```bash
bash scripts/trigger-sample-alert.sh
```

## Roadmap

### Phase 1: Portfolio MVP

- [ ] Self-host n8n with Docker Compose
- [ ] Build webhook alert trigger
- [ ] Add sample alert payload
- [ ] Add sample log retrieval
- [ ] Add GitHub commit lookup
- [ ] Add markdown runbook retrieval
- [ ] Add five agent prompts
- [ ] Generate structured incident summary
- [ ] Create GitHub Issue
- [ ] Send Slack notification
- [ ] Save Postgres audit record
- [ ] Generate postmortem draft

### Phase 2: Production MVP

- [ ] Real alert source integration
- [ ] Slack interactive approval buttons
- [ ] Jira and Linear integrations
- [ ] Runbook vector search
- [ ] Admin-configurable playbooks
- [ ] Multi-service support
- [ ] Integration health checks
- [ ] Audit export
- [ ] Incident timeline view

### Phase 3: Paid Product

- [ ] Multi-tenant architecture
- [ ] Organization/workspace model
- [ ] User roles and permissions
- [ ] Billing
- [ ] Usage limits
- [ ] Hosted cloud option
- [ ] Private deployment option
- [ ] SSO
- [ ] Long-term audit retention
- [ ] Custom playbook builder
- [ ] MSP/client workspace support

## Status

MVP design in progress.
