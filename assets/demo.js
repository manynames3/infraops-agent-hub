import { createAuditEvent, createIncidentPacket } from "./demo-engine.mjs";

const SOURCE_FILES = {
  alert: "sample-alerts/invoicebridge-5xx-alert.json",
  logs: "sample-logs/invoicebridge-errors.json",
  runbook: "runbooks/high-5xx-error-rate.md"
};

const state = {
  packet: null,
  auditEvent: null,
  persistence: null
};

const elements = {
  runButton: document.querySelector("[data-run-demo]"),
  statusText: document.querySelector("[data-demo-status]"),
  statusPanel: document.querySelector(".demo-status-panel"),
  packetRoot: document.querySelector("[data-packet-root]"),
  auditRoot: document.querySelector("[data-audit-root]"),
  jsonPreview: document.querySelector("[data-json-preview]")
};

function setStatus(message, tone = "neutral") {
  elements.statusText.textContent = message;
  elements.statusText.dataset.tone = tone;
  elements.statusPanel.dataset.tone = tone;
}

function createNode(tagName, className, text) {
  const node = document.createElement(tagName);
  if (className) {
    node.className = className;
  }
  if (text !== undefined) {
    node.textContent = text;
  }
  return node;
}

function renderList(items, className = "demo-list") {
  const list = createNode("ul", className);
  items.forEach((item) => {
    const entry = createNode("li", "", item);
    list.append(entry);
  });
  return list;
}

function renderMetric(label, value) {
  const item = createNode("div", "metric");
  item.append(createNode("span", "", label));
  item.append(createNode("strong", "", String(value ?? "unknown")));
  return item;
}

function renderCard(title, body, options = {}) {
  const card = createNode("article", `packet-card ${options.modifier || ""}`.trim());
  card.append(createNode("h3", "", title));
  if (body instanceof Node) {
    card.append(body);
  } else {
    card.append(createNode("p", "", body));
  }
  return card;
}

function renderTimeline(timeline) {
  const list = createNode("ol", "timeline-list");
  timeline.forEach((event) => {
    const item = createNode("li", "");
    const marker = createNode("span", `timeline-marker timeline-${event.type}`, event.type);
    const content = createNode("div", "");
    content.append(createNode("time", "", event.timestamp));
    content.append(createNode("strong", "", event.title));
    content.append(createNode("p", "", event.detail || ""));
    if (event.request_id) {
      content.append(createNode("code", "", event.request_id));
    }
    item.append(marker, content);
    list.append(item);
  });
  return list;
}

function renderPacket(packet) {
  elements.packetRoot.replaceChildren();

  const summary = createNode("section", "packet-summary");
  const summaryText = createNode("div", "");
  summaryText.append(createNode("p", "eyebrow", "Incident packet"));
  summaryText.append(createNode("h2", "", packet.incident.summary));
  summaryText.append(
    createNode(
      "p",
      "",
      "This packet is generated from sample alert, log, and runbook files. It makes no real AWS, Slack, GitHub, or LLM calls."
    )
  );

  const metrics = createNode("div", "metric-grid");
  metrics.append(
    renderMetric("Incident", packet.incident.id),
    renderMetric("Service", packet.incident.service),
    renderMetric("Severity", packet.incident.severity),
    renderMetric("5xx rate", `${packet.metrics.error_rate_percent}%`),
    renderMetric("Sampled 5xx", packet.metrics.sampled_5xx_count),
    renderMetric("Status", packet.incident.status.replaceAll("_", " "))
  );

  summary.append(summaryText, metrics);
  elements.packetRoot.append(summary);

  const cardGrid = createNode("section", "packet-grid");
  cardGrid.append(
    renderCard("Triage finding", renderList(packet.triage.evidence), { modifier: "card-blue" }),
    renderCard("Release correlation", packet.release_correlation.finding, { modifier: "card-amber" }),
    renderCard(
      "Runbook match",
      `${packet.runbook_lookup.selected_runbook} matched ${packet.runbook_lookup.matched_terms.join(", ")}.`,
      { modifier: "card-green" }
    ),
    renderCard("Operator handoff", packet.documentation.operator_handoff, { modifier: "card-blue" })
  );
  elements.packetRoot.append(cardGrid);

  const planning = createNode("section", "packet-columns");
  planning.append(
    renderCard("Read-only next steps", renderList(packet.next_steps.read_only), { modifier: "card-green" }),
    renderCard("Approval-required actions", renderList(packet.next_steps.approval_required), { modifier: "card-amber" }),
    renderCard("Blocked in demo mode", renderList(packet.next_steps.blocked), { modifier: "card-red" })
  );
  elements.packetRoot.append(planning);

  const timeline = createNode("section", "packet-section");
  timeline.append(createNode("h2", "", "Evidence timeline"));
  timeline.append(renderTimeline(packet.timeline));
  elements.packetRoot.append(timeline);

  const approval = createNode("section", "approval-panel");
  const approvalText = createNode("div", "");
  approvalText.append(createNode("p", "eyebrow", "Approval gate"));
  approvalText.append(createNode("h2", "", "Production-impacting actions stay blocked."));
  approvalText.append(createNode("p", "", packet.approval_gate.reason));
  const disabledButton = createNode("button", "button button-disabled", "Production action blocked");
  disabledButton.disabled = true;
  approval.append(approvalText, disabledButton);
  elements.packetRoot.append(approval);
}

function renderAudit(auditEvent, persistence) {
  elements.auditRoot.replaceChildren();

  const persistenceText = persistence?.message || "Stored as a browser audit preview for this hosted demo.";
  const persistenceTone = persistence?.inserted ? "Persisted" : "Preview";

  const auditCard = createNode("article", "audit-card");
  auditCard.append(createNode("p", "eyebrow", "Audit event"));
  auditCard.append(createNode("h2", "", auditEvent.summary));
  auditCard.append(createNode("p", "", persistenceText));

  const auditMeta = createNode("div", "audit-meta");
  auditMeta.append(
    renderMetric("Mode", persistenceTone),
    renderMetric("Table", auditEvent.table),
    renderMetric("Event type", auditEvent.event_type),
    renderMetric("Action class", auditEvent.action_class)
  );
  auditCard.append(auditMeta);
  elements.auditRoot.append(auditCard);

  elements.jsonPreview.textContent = JSON.stringify(
    {
      audit_event: auditEvent,
      persistence
    },
    null,
    2
  );
}

async function fetchJson(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Could not load ${path}`);
  }
  return response.json();
}

async function fetchText(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Could not load ${path}`);
  }
  return response.text();
}

async function runViaApi() {
  const response = await fetch("/api/run-demo-incident", {
    method: "POST",
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify({ sample: "invoicebridge-5xx" })
  });

  if (!response.ok) {
    throw new Error(`API demo unavailable (${response.status})`);
  }

  return response.json();
}

async function runInBrowser() {
  const [alert, logs, runbook] = await Promise.all([
    fetchJson(SOURCE_FILES.alert),
    fetchJson(SOURCE_FILES.logs),
    fetchText(SOURCE_FILES.runbook)
  ]);
  const packet = createIncidentPacket({
    alert,
    logs,
    runbook,
    sourceFiles: SOURCE_FILES
  });
  const auditEvent = createAuditEvent(packet);
  const localAuditKey = `infraops-demo-audit:${auditEvent.id}`;
  localStorage.setItem(localAuditKey, JSON.stringify(auditEvent));

  return {
    packet,
    audit_event: auditEvent,
    persistence: {
      inserted: false,
      mode: "browser-local-preview",
      message:
        "Stored in this browser's localStorage for the hosted demo. Configure a standard Postgres DATABASE_URL to persist audit events server-side."
    }
  };
}

async function runDemo() {
  setStatus("Running sample incident...", "running");
  elements.runButton.disabled = true;

  try {
    let result;
    try {
      result = await runViaApi();
    } catch (apiError) {
      result = await runInBrowser();
      result.persistence.api_fallback_reason = apiError.message;
    }

    state.packet = result.packet;
    state.auditEvent = result.audit_event;
    state.persistence = result.persistence;

    renderPacket(state.packet);
    renderAudit(state.auditEvent, state.persistence);
    setStatus("Sample incident packet generated. No external systems were called.", "ready");
  } catch (error) {
    setStatus(error.message, "error");
  } finally {
    elements.runButton.disabled = false;
  }
}

elements.runButton.addEventListener("click", runDemo);
runDemo();
