#!/usr/bin/with-contenv bashio
set -e

CONFIG_PATH=/homeassistant/otel/collector.yaml

DT_ENDPOINT="$(bashio::config 'dt_endpoint')"
DT_API_TOKEN="$(bashio::config 'dt_api_token')"
LOG_LEVEL="$(bashio::config 'log_level')"

if bashio::var.is_empty "${DT_ENDPOINT}"; then
    bashio::exit.nok "dt_endpoint is not set — add your tenant's OTLP base URL (https://<env-id>.live.dynatrace.com/api/v2/otlp) in the add-on Configuration tab."
fi

if bashio::var.is_empty "${DT_API_TOKEN}"; then
    bashio::exit.nok "dt_api_token is not set — add it in the add-on Configuration tab."
fi

if ! bashio::fs.file_exists "${CONFIG_PATH}"; then
    bashio::exit.nok "${CONFIG_PATH} not found — deploy it with script.git_pull_and_reload first."
fi

# SUPERVISOR_TOKEN is injected by Supervisor; the collector reads it via
# ${env:SUPERVISOR_TOKEN} to authenticate the /api/prometheus scrape.
export DT_ENDPOINT DT_API_TOKEN SUPERVISOR_TOKEN

bashio::log.info "Exporting to ${DT_ENDPOINT}"
bashio::log.info "OTLP/HTTP receiver listening on :4318"

exec /usr/local/bin/dynatrace-otel-collector \
    --config="${CONFIG_PATH}" \
    --set=service.telemetry.logs.level="${LOG_LEVEL}"
