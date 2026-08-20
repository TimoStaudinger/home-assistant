# Dynatrace's own collector distribution — their production recommendation
# (they class upstream contrib as testing-only), same verified component set,
# Dynatrace-supported ARM64 builds and security patching. The image is FROM
# scratch — no shell, so bashio can't run in it. Lift the static binary out
# and drop it on Home Assistant's base image, which brings s6-overlay and
# bashio for reading add-on options.
# BUILD_FROM must be declared before the first FROM — an ARG between stages
# is scoped to the preceding stage and invisible to the next FROM.
ARG BUILD_FROM
FROM dynatrace/dynatrace-otel-collector:0.54.0 AS otel

FROM ${BUILD_FROM}

COPY --from=otel /dynatrace-otel-collector /usr/local/bin/dynatrace-otel-collector

COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
