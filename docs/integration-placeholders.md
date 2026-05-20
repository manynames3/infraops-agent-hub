# Integration Placeholders

This MVP uses placeholders only. Future integrations should be added behind feature flags and should default to disabled.

## AWS

Current state:

- Mock CloudWatch-style alert payloads.
- No AWS SDK calls.
- No credentials required.

Future scope:

- Read-only CloudWatch metrics.
- Read-only ECS service descriptions.
- Read-only RDS storage metrics.
- Explicit approval before any mutating action.

## Slack

Current state:

- Approval prompt template only.
- No Slack API calls.

Future scope:

- Draft approval messages.
- Require human button click or signed decision.
- Store Slack message timestamp and approver identity in audit records.

## GitHub

Current state:

- Mock GitHub Actions alert payload.
- No issue, PR, or workflow API calls.

Future scope:

- Create follow-up issues after approval.
- Link incidents to pull requests.
- Read CI failure metadata with least-privilege access.

## LLM Provider

Current state:

- Prompt templates only.
- No model calls.

Future scope:

- Provider adapter with redaction.
- Model and prompt version capture.
- Deterministic tests for safety boundaries.
- Token and cost accounting.
