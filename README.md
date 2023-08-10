# pontos-hub

This repository contains the blueprint for setting up the PONTOS datahub, developed as part of the PONTOS project.

For further information about the project and how to access the live instance of the PONTOS datahub, see here: https://pontos.ri.se

This repository will describe the technical setup of the datahub.

## Overview

The datahub consists of several containerized applications defined through multiple docker-compose files that together offers the following core functionality:

* A timeseries database ([TimescaleDB](https://github.com/timescale/timescaledb))
* A REST API for the database ([PostgREST](https://github.com/PostgREST/postgrest))
* A MQTT API for the database and for (near) real-time data ([EMQX](https://github.com/emqx/emqx))
* Data ingestion from the MQTT API to the timeseries database ([pontos-data-ingestor](https://github.com/MO-RISE/pontos-data-ingestor))

The core functionality is supported by:

* A reverse proxy ([Traefik](https://github.com/traefik/traefik))
* Automatically generated REST api documentation ([Swagger-UI](https://github.com/swagger-api/swagger-ui))
* A JWT-based authn/authz solution (see below for more details)


### Authn / Authz
TODO: Describe this in detail!


## Deploy

The datahub can be partially configured using environment variables, for example using a `.env` fil in conjunction with the docker-compose files. An example `.env` file is included in the repository [here](example.env).

To start the datahub in base mode (no TLS, no auth):

`docker compose -f docker-compose.base.yml up -d`

To start the datahub with auth and TLS support:

`docker compose -f docker-compose.base.yml -f docker-compose.auth.yml -f docker-compose.https.yml up -d`


## Development
The repository includes a devcontainer setup which is the recommended way of creating a development environment. See [here](https://code.visualstudio.com/docs/devcontainers/containers) for a generic get-started in VSCode.

To run the integration test suite:
```cmd
bats tests/
```

## License
See [LICENSE](./LICENSE)
