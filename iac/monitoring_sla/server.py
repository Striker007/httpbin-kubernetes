#!/usr/bin/env python3
import http.server
import urllib.request
import os
from datetime import datetime, timezone

METRICS_URL    = os.environ.get("TRAEFIK_METRICS", "http://traefik-metrics.kube-system.svc.cluster.local:9100/metrics")
SERVICE_FILTER = os.environ.get("SLA_SERVICE", "httpbin")
REFRESH        = int(os.environ.get("REFRESH_INTERVAL", "10"))
PORT           = int(os.environ.get("PORT", "8080"))


def fetch_metrics():
    try:
        with urllib.request.urlopen(METRICS_URL, timeout=4) as r:
            return r.read().decode(), None
    except Exception as e:
        return None, str(e)


def parse(raw):
    total = s2xx = s4xx = s5xx = 0
    for line in raw.splitlines():
        if not line.startswith("traefik_service_requests_total"):
            continue
        if SERVICE_FILTER not in line:
            continue
        try:
            v = float(line.rsplit(" ", 1)[1])
        except (ValueError, IndexError):
            continue
        total += v
        if 'code="2' in line:   s2xx += v
        elif 'code="4' in line: s4xx += v
        elif 'code="5' in line: s5xx += v
    return int(total), int(s2xx), int(s4xx), int(s5xx)


def render(total, s2xx, s4xx, s5xx, error=None):
    avail    = f"{(total - s5xx) / total * 100:.2f}" if total > 0 else "N/A"
    now      = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    color    = "#28a745" if total > 0 and s5xx == 0 else "#dc3545" if s5xx > 0 else "#6c757d"
    err_html = f"<p class='err'>Metrics unavailable: {error}</p>" if error else ""
    return f"""<!DOCTYPE html>
<html><head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="{REFRESH}">
  <title>httpbin SLA</title>
  <style>
    body  {{ font-family: monospace; max-width: 540px; margin: 48px auto; padding: 0 20px; background: #f8f9fa; }}
    h1    {{ color: #343a40; margin-bottom: 4px; }}
    .avail{{ font-size: 3em; font-weight: bold; color: {color}; margin: 8px 0 24px; }}
    table {{ border-collapse: collapse; width: 100%; background: #fff; }}
    th,td {{ padding: 9px 14px; border: 1px solid #dee2e6; }}
    th    {{ background: #343a40; color: #fff; text-align: left; }}
    .ts   {{ color: #6c757d; font-size: .8em; margin-top: 12px; }}
    .err  {{ color: #dc3545; }}
  </style>
</head><body>
  <h1>httpbin SLA</h1>
  <div class="avail">{avail}%</div>
  {err_html}
  <table>
    <tr><th>Status</th><th>Requests</th></tr>
    <tr><td>Total</td><td>{total}</td></tr>
    <tr><td>2xx</td><td>{s2xx}</td></tr>
    <tr><td>4xx</td><td>{s4xx}</td></tr>
    <tr><td>5xx</td><td>{s5xx}</td></tr>
  </table>
  <p class="ts">Updated: {now} &bull; refresh: {REFRESH}s &bull; filter: {SERVICE_FILTER}@traefik</p>
</body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        raw, err = fetch_metrics()
        html = render(*parse(raw)) if raw else render(0, 0, 0, 0, error=err)
        body = html.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"SLA monitor on :{PORT}  metrics={METRICS_URL}  filter={SERVICE_FILTER}", flush=True)
    http.server.HTTPServer(("", PORT), Handler).serve_forever()
