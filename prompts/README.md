# Prompt Templates

These prompts define the behavior expected from the future agent layer. They are templates only. This MVP does not call a real LLM provider.

Use these files as stable contracts between the workflow layer, the approval model, and future provider adapters.

Rules for every prompt:

- Treat all integrations as mock data unless explicitly configured otherwise in a later implementation.
- Never invent production facts.
- Never recommend destructive action without a rollback path and approval requirement.
- Always separate observation, inference, recommendation, and required approval.
- Redact secrets, tokens, customer data, and personal data from outputs.
