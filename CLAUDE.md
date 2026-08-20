# Home Assistant Configuration

## Architecture

- **Scenes** (`scenes/`) are the source of truth for which entities are on/off and at what brightness
  - `home.yaml` — activated when arriving home (via `script.hello`)
  - `gone.yaml` — activated when leaving (via `script.goodbye`)
  - When adding or removing an entity, update **both** scenes
- **Scripts** (`scripts/`) trigger scenes and handle sequencing
  - `hello.yaml` / `goodbye.yaml` — main entry points, exposed to HomeKit
  - `git_pull_and_reload.yaml` — deploy script (pulls git, reloads all YAML)
- **Automations** (`automations/`) react to state changes (e.g. guest mode)
- **Lovelace** (`lovelace/home.yaml`) — dashboard config; useful reference for all active entity IDs
- **Observability** (`otel/`, `addons/`) — Dynatrace instrumentation over OTLP; see `addons/README.md`
  - `otel/collector.yaml` deploys to `/config/otel/collector.yaml` and is read by the collector add-on
  - `addons/otel-collector/` is **not** deployed by `git_pull_and_reload` — `/addons` is outside `/config` and must be copied to the Pi by hand
  - No OneAgent: HAOS is immutable, so host metrics come from the collector's `hostmetrics` scraper

## Deploy

After pushing changes, trigger the deploy script via the HA REST API:

```
POST {{host}}/api/services/script/git_pull_and_reload
Authorization: Bearer {{token}}
```

Credentials are in `http-client.env.json` (local environment). The script runs `git pull --rebase` on `/config` and then calls `homeassistant.reload_all`.

The HA conversation agent does **not** have access to scripts — use the REST API instead.
