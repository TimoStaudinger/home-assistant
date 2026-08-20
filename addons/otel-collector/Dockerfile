# Dynatrace's own collector distribution — their production recommendation
# (they class upstream contrib as testing-only), same verified component set,
# Dynatrace-supported ARM64 builds and security patching. The image is FROM
# scratch — no shell, so bashio can't run in it. Lift the static binary out
# and drop it on Home Assistant's base image, which brings s6-overlay and
# bashio for reading add-on options.
FROM dynatrace/dynatrace-otel-collector:0.54.0 AS otel

ARG BUILD_FROM
FROM ${BUILD_FROM}

COPY --from=otel /dynatrace-otel-collector /usr/local/bin/dynatrace-otel-collector

COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
