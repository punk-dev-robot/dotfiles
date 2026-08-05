# Headroom metrics → Logfire (manual OTel collector)

Headroom (LLM proxy, `127.0.0.1:8788`) exposes Prometheus text at `/metrics` but has no
OTLP exporter. An `otelcol-contrib` instance scrapes it and pushes to the existing Pi
Logfire EU project. Lifecycle is **manual on purpose** — no LaunchAgent, no direnv hook,
no Pi autostart (past worktree/autostart breakage).

## Architecture

```
headroom :8788/metrics ──scrape 30s──▶ otelcol-contrib ──OTLP/HTTP──▶ logfire-eu.pydantic.dev
                                        resource: service.name=headroom
                                                  service.namespace=nothing
```

## Files

| Path | Purpose |
| --- | --- |
| `config/mac/otelcol/config.yaml` → `~/.config/otelcol/config.yaml` | collector pipeline |
| `local/bin/otelcol-headroom` → `~/.local/bin/otelcol-headroom` | install + lifecycle wrapper |
| `~/.local/state/otelcol/headroom.{pid,log}` | runtime state (not in repo) |

## Usage

```sh
otelcol-headroom install    # pinned v0.157.0 from GitHub releases, SHA-256 verified
otelcol-headroom start      # validates config, launches detached, checks it survives
otelcol-headroom status
otelcol-headroom stop
otelcol-headroom restart
```

## Secret handling

The shell already exports `OTEL_EXPORTER_OTLP_HEADERS=Authorization=<token>` (may hold
several comma-separated headers). The collector does **not** read that SDK env var, so
`start` parses it, takes the case-insensitive `Authorization=` entry, and passes only its
value to the child as `LOGFIRE_AUTHORIZATION`, which `config.yaml` reads via
`${env:LOGFIRE_AUTHORIZATION}`. No `eval`/`source`, no logging of the value. Missing or
empty auth → `start` refuses.

## Verify in Logfire

```sql
SELECT metric_name, count(*)
FROM metrics
WHERE service_name = 'headroom' AND service_namespace = 'nothing'
  AND recorded_timestamp > now() - interval '15 minutes'
GROUP BY metric_name
```

Expect data ~1 min after `start` (30 s scrape + batch). Current result: 28 stable
Prometheus series → 33 exported metrics/data points, all low cardinality, safe with
`HEADROOM_TELEMETRY=off`.

## Behaviour when Headroom is down

Collector remains running and retries while Headroom is unavailable; scrape errors appear in
the collector log. Scraping resumes without a collector restart when Headroom returns.

## Upgrades

Version is pinned in `otelcol-headroom` (`VERSION=0.157.0`). Bump the variable and rerun
`install`. Homebrew has no official tap for `otelcol-contrib` — do not switch to `brew`.
Config uses the stable component name `otlp_http/logfire` (not the deprecated `otlphttp`).

## Failure modes

| Symptom | Cause / fix |
| --- | --- |
| `no Authorization entry in OTEL_EXPORTER_OTLP_HEADERS` | shell lacks the secret env; open a shell where 1Password/secrets are loaded |
| `collector exited at startup; see …/headroom.log` | bad config or port conflict; read log tail |
| `config validation failed` | edit `config/mac/otelcol/config.yaml`, redeploy with `dotter -v` |
| `$BIN not installed` | run `otelcol-headroom install` (needs `gh` authenticated) |
| no data in Logfire, log clean | wrong token/project, or query window shorter than one 30 s scrape |
