import { readFile } from "node:fs/promises";
import { createAuditEvent, createIncidentPacket } from "../assets/demo-engine.mjs";

const [alertRaw, logsRaw, runbook] = await Promise.all([
  readFile("sample-alerts/invoicebridge-5xx-alert.json", "utf8"),
  readFile("sample-logs/invoicebridge-errors.json", "utf8"),
  readFile("runbooks/high-5xx-error-rate.md", "utf8")
]);

const packet = createIncidentPacket({
  alert: JSON.parse(alertRaw),
  logs: JSON.parse(logsRaw),
  runbook,
  sourceFiles: {
    alert: "sample-alerts/invoicebridge-5xx-alert.json",
    logs: "sample-logs/invoicebridge-errors.json",
    runbook: "runbooks/high-5xx-error-rate.md"
  },
  generatedAt: "2026-05-20T14:16:00.000Z"
});

const auditEvent = createAuditEvent(packet);

const assertions = [
  [packet.incident.id === "inc-invoicebridge-2026-05-20-001", "incident id should match sample alert"],
  [packet.metrics.sampled_5xx_count === 4, "sampled 5xx count should be deterministic"],
  [packet.approval_gate.production_apply_allowed === false, "production apply must be blocked"],
  [packet.safety.external_api_calls === 0, "demo must make no external API calls"],
  [auditEvent.table === "infraops_audit.audit_events", "audit event should target Postgres audit table"],
  [auditEvent.action_class === "read_only", "demo audit event should be read-only"]
];

for (const [passed, message] of assertions) {
  if (!passed) {
    throw new Error(message);
  }
}

console.log("  ok hosted demo engine");
