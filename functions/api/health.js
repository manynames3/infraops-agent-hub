function jsonResponse(body) {
  return new Response(JSON.stringify(body, null, 2), {
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store"
    }
  });
}

export function onRequest() {
  return jsonResponse({
    status: "ok",
    service: "infraops-agent-hub",
    mode: "mock",
    external_api_calls: 0,
    production_changes: 0
  });
}
