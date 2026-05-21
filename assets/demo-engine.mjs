const READ_ONLY_STEPS = [
  "Review route-level 5xx rate for /v1/invoices/render and /v1/webhooks/deliver.",
  "Compare sampled errors before and after invoicebridge-api@2026.05.20.3.",
  "Inspect renderer timeout metrics and queue depth using approved read-only telemetry.",
  "Collect representative request IDs before proposing any production change."
];

const APPROVAL_REQUIRED_STEPS = [
  "Rollback invoicebridge-api@2026.05.20.3.",
  "Change renderer timeout, retry, queue, or rate-limit settings.",
  "Restart invoicebridge-api workloads.",
  "Send customer-facing incident communications."
];

const BLOCKED_STEPS = [
  "Do not mutate production from demo mode.",
  "Do not send external Slack, GitHub, AWS, or LLM requests from demo mode.",
  "Do not execute rollback, restart, scale, or config changes without a human approval record."
];

function countBy(items, getKey) {
  return items.reduce((counts, item) => {
    const key = getKey(item) || "unknown";
    counts[key] = (counts[key] || 0) + 1;
    return counts;
  }, {});
}

function topKey(counts) {
  return Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] || "unknown";
}

function extractRunbookSignals(runbook) {
  const lower = runbook.toLowerCase();
  return ["5xx", "timeout", "release", "rollback", "customer-facing", "approval"].filter((term) =>
    lower.includes(term)
  );
}

function buildTimeline(alert, logs, errorEntries) {
  const releaseEvents = (logs.release_events || []).map((event) => ({
    type: "release",
    timestamp: event.timestamp,
    title: event.release,
    detail: event.change_summary,
    actor: event.actor
  }));

  const sampledErrors = errorEntries.slice(0, 4).map((entry) => ({
    type: "error",
    timestamp: entry.timestamp,
    title: `${entry.status} on ${entry.route}`,
    detail: entry.message,
    request_id: entry.request_id
  }));

  return [
    {
      type: "alert",
      timestamp: alert.started_at,
      title: alert.summary,
      detail: `${alert.service} in ${alert.environment}`
    },
    ...releaseEvents,
    ...sampledErrors
  ].sort((left, right) => String(left.timestamp).localeCompare(String(right.timestamp)));
}

function buildIncidentSummary(alert, logs, dominantRoute, releaseConfidence) {
  const impact = alert.labels?.customer_impact || "Customer impact has not been classified.";
  return (
    `${alert.service} is above its 5xx threshold in ${alert.environment}. ` +
    `Sampled errors are concentrated on ${dominantRoute}. ` +
    `Release correlation is ${releaseConfidence}. ${impact}`
  );
}

export function createIncidentPacket({ alert, logs, runbook, sourceFiles, generatedAt }) {
  const generated = generatedAt || new Date().toISOString();
  const entries = logs.entries || [];
  const errorEntries = entries.filter((entry) => Number(entry.status || 0) >= 500);
  const statusCounts = countBy(errorEntries, (entry) => String(entry.status));
  const routeCounts = countBy(errorEntries, (entry) => entry.route);
  const releaseCounts = countBy(errorEntries, (entry) => entry.release);
  const dominantRoute = topKey(routeCounts);
  const dominantRelease = topKey(releaseCounts);
  const releaseEvent = (logs.release_events || []).find((event) => event.release === dominantRelease);
  const releaseConfidence = releaseEvent ? "medium" : "low";
  const requestIds = errorEntries.map((entry) => entry.request_id).filter(Boolean).slice(0, 4);
  const summary = buildIncidentSummary(alert, logs, dominantRoute, releaseConfidence);
  const runbookSignals = extractRunbookSignals(runbook);
  const releaseFinding = releaseEvent
    ? `Errors are concentrated on ${dominantRelease}, deployed at ${releaseEvent.timestamp} by ${releaseEvent.actor}.`
    : "No matching release event was found in the sample logs.";

  return {
    schema_version: "incident-packet.v1",
    generated_at: generated,
    mode: "mock",
    source_files: sourceFiles,
    incident: {
      id: alert.incident_id,
      alert_id: alert.alert_id,
      source: alert.source,
      provider: alert.provider,
      service: alert.service,
      environment: alert.environment,
      severity: alert.severity,
      status: "human_review_required",
      started_at: alert.started_at,
      summary
    },
    metrics: {
      error_rate_percent: alert.metric_context?.error_rate_percent,
      threshold_percent: alert.metric_context?.threshold_percent,
      request_count: alert.metric_context?.request_count,
      error_count: alert.metric_context?.error_count,
      window: alert.metric_context?.window,
      sampled_5xx_count: errorEntries.length,
      status_counts: statusCounts,
      route_counts: routeCounts
    },
    triage: {
      finding: `${alert.service} is above the configured 5xx threshold with ${alert.metric_context?.error_rate_percent} percent errors.`,
      customer_impact: alert.labels?.customer_impact,
      severity: alert.severity,
      confidence: "medium",
      evidence: [
        alert.summary,
        `${errorEntries.length} sampled 5xx log entries in ${logs.time_window?.start} to ${logs.time_window?.end}.`,
        `Dominant affected route: ${dominantRoute}.`,
        `Representative request IDs: ${requestIds.join(", ")}.`
      ]
    },
    release_correlation: {
      finding: releaseFinding,
      confidence: releaseConfidence,
      release_event: releaseEvent || null,
      dominant_release: dominantRelease,
      sample_request_ids: requestIds
    },
    runbook_lookup: {
      selected_runbook: sourceFiles?.runbook || "runbooks/high-5xx-error-rate.md",
      matched_terms: runbookSignals,
      reason: "The alert and sampled logs indicate elevated HTTP 5xx responses after a recent release."
    },
    timeline: buildTimeline(alert, logs, errorEntries),
    next_steps: {
      read_only: READ_ONLY_STEPS,
      approval_required: APPROVAL_REQUIRED_STEPS,
      blocked: BLOCKED_STEPS
    },
    approval_gate: {
      status: "required_before_production_impact",
      production_apply_allowed: false,
      proposed_action: "Rollback or configuration change for invoicebridge-api",
      reason: "The likely fix could affect live traffic, deployment state, customer-facing behavior, or incident evidence.",
      rollback_plan: "Use the approved release rollback process and capture pre/post health checks.",
      required_decider: "human incident commander or service owner"
    },
    documentation: {
      incident_note: summary,
      operator_handoff:
        "Continue read-only diagnosis. Request human approval before rollback, restart, scaling, configuration change, or external communication.",
      slack_summary_preview:
        "InvoiceBridge 5xx spike remains in human-review mode. Evidence points to renderer timeouts after invoicebridge-api@2026.05.20.3. No production action has been taken."
    },
    safety: {
      external_api_calls: 0,
      production_changes: 0,
      real_llm_calls: 0,
      human_approval_required: true
    }
  };
}

export function createAuditEvent(packet, { id, recordedAt } = {}) {
  const recordId =
    id ||
    `audit-preview-${packet.incident.id}-${String(recordedAt || packet.generated_at)
      .replace(/[^0-9A-Za-z]/g, "")
      .slice(0, 14)}`;

  return {
    id: recordId,
    table: "infraops_audit.audit_events",
    incident_id: packet.incident.id,
    event_type: "triage.recommendation.created",
    actor: "infraops-agent-hub-demo",
    action_class: "read_only",
    summary: `Mock triage for ${packet.incident.id} identified elevated 5xx responses on ${packet.incident.service}.`,
    evidence: {
      packet_schema_version: packet.schema_version,
      source_files: packet.source_files,
      triage: packet.triage,
      release_correlation: packet.release_correlation,
      runbook_lookup: packet.runbook_lookup,
      next_steps: packet.next_steps,
      approval_gate: packet.approval_gate,
      safety: packet.safety
    },
    recorded_at: recordedAt || packet.generated_at
  };
}
