import { neon } from "@neondatabase/serverless";
import { createAuditEvent, createIncidentPacket } from "../../assets/demo-engine.mjs";

const SOURCE_FILES = {
  alert: "sample-alerts/invoicebridge-5xx-alert.json",
  logs: "sample-logs/invoicebridge-errors.json",
  runbook: "runbooks/high-5xx-error-rate.md"
};

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store"
    }
  });
}

async function fetchAsset(context, path) {
  const url = new URL(context.request.url);
  url.pathname = `/${path}`;
  url.search = "";

  const request = new Request(url.toString(), {
    method: "GET"
  });

  const response = context.env?.ASSETS?.fetch ? await context.env.ASSETS.fetch(request) : await fetch(request);
  if (!response.ok) {
    throw new Error(`Could not load demo asset ${path}`);
  }
  return response;
}

async function loadDemoSources(context) {
  const [alertResponse, logsResponse, runbookResponse] = await Promise.all([
    fetchAsset(context, SOURCE_FILES.alert),
    fetchAsset(context, SOURCE_FILES.logs),
    fetchAsset(context, SOURCE_FILES.runbook)
  ]);

  return {
    alert: await alertResponse.json(),
    logs: await logsResponse.json(),
    runbook: await runbookResponse.text()
  };
}

function neonUrlRequiresSsl(databaseUrl) {
  try {
    const url = new URL(databaseUrl);
    return url.searchParams.get("sslmode") === "require";
  } catch {
    return false;
  }
}

async function persistAuditEvent(env, auditEvent) {
  if (env?.ENABLE_HOSTED_AUDIT_WRITES !== "true") {
    return {
      inserted: false,
      mode: "server-preview-audit-writes-disabled",
      message:
        "Generated server-side as an audit-event preview. Set ENABLE_HOSTED_AUDIT_WRITES=true and configure a Postgres adapter to persist."
    };
  }

  if (!env?.DATABASE_URL) {
    return {
      inserted: false,
      mode: "database-url-missing",
      message: "Hosted audit writes are enabled, but DATABASE_URL is not configured."
    };
  }

  if (env?.DATABASE_PROVIDER !== "neon") {
    return {
      inserted: false,
      mode: "postgres-provider-not-enabled",
      message:
        "Hosted Pages Functions currently support the Neon serverless Postgres adapter. Use AWS RDS from an AWS-hosted API or a deliberate Cloudflare Hyperdrive design."
    };
  }

  if (!neonUrlRequiresSsl(env.DATABASE_URL)) {
    return {
      inserted: false,
      mode: "neon-ssl-required",
      message: "Neon hosted audit writes require DATABASE_URL to include sslmode=require."
    };
  }

  try {
    const sql = neon(env.DATABASE_URL);
    const evidence = JSON.stringify(auditEvent.evidence);
    const rows = await sql`
      INSERT INTO infraops_audit.audit_events (
        incident_id,
        event_type,
        actor,
        action_class,
        summary,
        evidence
      )
      VALUES (
        ${auditEvent.incident_id},
        ${auditEvent.event_type}::infraops_audit.audit_event_type,
        ${auditEvent.actor},
        ${auditEvent.action_class}::infraops_audit.action_class,
        ${auditEvent.summary},
        ${evidence}::jsonb
      )
      RETURNING id, recorded_at;
    `;

    return {
      inserted: true,
      mode: "neon-postgres",
      audit_event_id: rows[0]?.id,
      recorded_at: rows[0]?.recorded_at,
      message: "Persisted one audit event to standard Postgres through the Neon serverless adapter."
    };
  } catch (error) {
    return {
      inserted: false,
      mode: "postgres-write-failed",
      message: "The incident packet was generated, but the hosted audit insert failed.",
      detail: error.message
    };
  }
}

export async function onRequest(context) {
  if (!["GET", "POST"].includes(context.request.method)) {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const { alert, logs, runbook } = await loadDemoSources(context);
    const packet = createIncidentPacket({
      alert,
      logs,
      runbook,
      sourceFiles: SOURCE_FILES
    });
    const auditEvent = createAuditEvent(packet);

    return jsonResponse({
      packet,
      audit_event: auditEvent,
      persistence: await persistAuditEvent(context.env, auditEvent)
    });
  } catch (error) {
    return jsonResponse(
      {
        error: "Demo incident failed",
        detail: error.message
      },
      500
    );
  }
}
