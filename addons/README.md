# Dynatrace instrumentation

Telemetry from Home Assistant and the Raspberry Pi is shipped to Dynatrace over
OTLP. There is no OneAgent: Home Assistant OS is an immutable Buildroot image
with a read-only rootfs and no package manager, and OTA updates replace the
whole system partition — nothing installed onto the host would survive.

```
Raspberry Pi (HAOS)
├─ prometheus: integration ──── scrape ────┐
│    built-in, all entities                │
├─ remote_logger (HACS) ─── OTLP :4318 ────┼──► dynatrace-otel-collector ──► Dynatrace
│    logs + state changes + service calls  │       (add-on)
└─ Pi /proc ─────────────── hostmetrics ───┘
```

Three pipelines, no custom code. The collector is the only component that holds
the Dynatrace token, which is why `remote_logger` points at it rather than
straight at the tenant.

## 1. Create the Dynatrace token

Two token types work; the add-on's `dt_auth_scheme` option selects between them.

**Platform token (default, `Bearer`)** — per-user, no admin permission needed.
Create it under **Account Management → My platform tokens** (or search
"platform tokens" in the product). Select the ingest/write scopes offered in
the picker (search for "ingest"). Endpoint for the add-on:
`https://<env-id>.apps.dynatrace.com/platform/otlp`. If a scope is missing,
the collector log's 403 body names it exactly — add it to the token and
restart the add-on.

**Classic access token (`Api-Token`)** — needs permission for the classic
*Access Tokens* app. Scopes `metrics.ingest` + `logs.ingest`; endpoint
`https://<env-id>.live.dynatrace.com/api/v2/otlp` (drop `.apps`).

Either way the token is shown **once** and goes only into the add-on's
Configuration tab — never into this repo, and not into Home Assistant.

## 2. Install the collector add-on

The Supervisor reads local add-ons from `/addons`, which is not part of `/config`
and so is not covered by `script.git_pull_and_reload`. Copy it manually:

1. Install the **Samba share** or **Advanced SSH & Web Terminal** add-on if you
   don't already have one.
2. Copy `addons/otel-collector/` from this repo into `/addons/otel-collector/`
   on the Pi.
3. **Settings → Add-ons → Add-on Store → ⋮ → Check for updates**. The add-on
   appears under *Local add-ons*.
4. Install it. The first build takes a few minutes on a Pi 4 — it pulls the
   collector image and Home Assistant's aarch64 base.
5. On the **Configuration** tab, paste the token into `dt_api_token`, set
   `dt_endpoint` to the OTLP base URL for your token type (see step 1), and
   leave `dt_auth_scheme: Bearer` for a platform token. The tenant URL lives
   only here, never in git.
6. Start it, and enable **Start on boot** and **Watchdog**.

The collector reads its pipeline config from `/config/otel/collector.yaml`,
which *is* version-controlled here — so pipeline changes deploy through the
normal git flow, and only the token lives outside the repo.

## 3. Enable the Home Assistant side

`prometheus:` and `rest_command:` are already in `configuration.yaml` and need
no secrets: deploy markers go to the local collector as OTLP/JSON log records
(`http://localhost:4318/v1/logs` — HA Core is host-networked on HAOS), and the
collector attaches auth on export.

Install `remote_logger` via HACS:

1. **HACS → Integrations → ⋮ → Custom repositories**, add
   `https://github.com/rhizomatics/remote_logger` as an Integration.
2. Download it and restart Home Assistant.
3. **Settings → Devices & Services → Add Integration → Remote Logger**.
4. Configure it for **OTLP** over **HTTP** to `http://localhost:4318`, protobuf
   encoding. Enable event forwarding for state changes and service calls.

## 4. Verify

- Add-on **Log** tab: `Everything is ready. Begin running and processing data.`
  and no exporter errors. A 401 means the token or its scopes are wrong.
- Collector health: `http://homeassistant.local:13133` returns HTTP 200.
- In Dynatrace, `fetch logs | filter service.name == "home-assistant"` and
  `timeseries avg(system.cpu.utilization)` should both return rows within a
  couple of minutes.
- Deploy markers: run `script.git_pull_and_reload`, then
  `fetch logs | filter event.type == "CUSTOM_DEPLOYMENT"`.

## Notes

- **What is not covered.** Without OneAgent there is no host entity in
  Smartscape, no process-level deep monitoring, and no automatic dependency
  mapping. Host metrics arrive as plain OTLP metrics.
- **Privacy.** `sensor.*_geocoded_location` is excluded from the Prometheus
  filter on purpose — those hold street addresses. Anything added to the
  exclusion list applies to the scrape only; `remote_logger` forwards state
  changes independently, so check its own filtering if that matters.
- **Temporality.** Dynatrace ingests delta temporality only; the
  `cumulativetodelta` processor converts the cumulative sums that the
  Prometheus scrape and hostmetrics emit. Without it, every counter is
  silently dropped while gauges still arrive — it looks healthy and isn't.
- **Cardinality.** The scrape covers all ~379 entities every 30s. If ingest
  volume becomes a problem, narrow it with `include_domains` in the
  `prometheus:` filter rather than by lengthening the scrape interval.
