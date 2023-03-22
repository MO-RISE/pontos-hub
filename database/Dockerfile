FROM ubuntu:22.04 AS templater

ARG AUTHENTICATOR_PASSWORD
ENV AUTHENTICATOR_PASSWORD=${AUTHENTICATOR_PASSWORD}

RUN apt-get update && apt-get install -y curl && curl -L https://github.com/a8m/envsubst/releases/download/v1.4.2/envsubst-`uname -s`-`uname -m` -o envsubst && chmod +x envsubst && mv envsubst /usr/local/bin

COPY docker-entrypoint-initdb.d/* /templates/

RUN for f in $(find /templates -type f -name '*.template'); do echo $f && envsubst -no-unset -no-empty < "${f}" > "${f%.template}" && rm -rf $f; done


FROM timescale/timescaledb:2.10.1-pg15

COPY --from=templater /templates/* /docker-entrypoint-initdb.d/
