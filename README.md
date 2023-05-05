# pontos-hub

This repository contains the blueprint for setting up the PONTOS datahub, developed as part of the PONTOS project.

For further information about the project and how to access the live instance of the PONTOS datahub, see here: https://pontos.ri.se

This repository will describe the technical setup of the datahub.

## Overview

The datahub is consists of several containerized applications defined through multiple docker-compose files.

The datahub can be partially configured using environment variables, for example using a `.env` fil in conjunction with the docker-compose files. An example `.env` file is included in the repository [here](example.env).

To start the datahub in base mode (no TLS, no auth):

`docker compose -f docker-compose.base.yml up -d`

To start the datahub with automatically generated TLS certificates (no auth):

`docker compose -f docker-compose.base.yml -f docker-compose.https.yml up -d`

(WIP) To start the datahub with automatically generated TLS certificates and authentication:

`docker compose -f docker-compose.base.yml -f docker-compose.https.yml -f docker-compose.auth.yml up -d`

## Database

The datahub relies on a TimescaleDB database setup that is initially (first boot) configured using a set of scripts that can be found in [database/docker-entrypoint-initdb.d](database/docker-entrypoint-initdb.d).

The data is stored in a narrow table format to allow for maximum flexibility regarding data compatibility.

## REST API

The datahub makes use of PostgREST to generate a read-only REST API towards the data stored in the database. Depending on the configuration, the REST API is either open (allows anonymous access) or closed (requires authentication).

An OpenAPI compliant documentation of the REST API is made available and visualized using SwaggerUI.

The REST API is hosted on `/api` and the documentation on `/docs`.

## MQTT interface

The datahub provides an MQTT interface, primarily for publishing data to the hub. It makes use of the mqtt-over-websocket schema to allow for secured remote connections using the same TLS certificate as the REST API.

The MQTT interface is hosted on `/mqtt`.

For some basic example scripts to publish data to the MQTT interface, see the [examples folder](./examples/README.md).

## Data ingestor

See https://github.com/MO-RISE/pontos-data-ingestor

## Authentication and Authorization
Authentication is performed using JWT tokens by:
* PostgREST (for reuqests to the API)
* EMQX (for connections to the MQTT broker)
respectively.

The reverse proxy (Traefik) does not perform any form of auth (nether authentcation nor authorization)

Example of creating a valid JWT token that includes a role for PostgREST and a specific acl configuration for EMQX:
```
jwt encode --exp=1w --secret=<your_secret> '{"role": "web_user", "acl": {"pub": ["PONTOS/<vessel_id>/<parameter_id>/+"]}}'
```