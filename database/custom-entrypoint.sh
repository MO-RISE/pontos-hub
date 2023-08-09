#!/usr/bin/env bash
set -Eeo pipefail

# Custom entrypoint to always run files in /always-initdb.d/
# See https://github.com/docker-library/postgres/pull/496 for details.

# shellcheck source=/dev/null
source "$(which docker-entrypoint.sh)"

docker_setup_env
docker_create_db_directories

# If root, restart as postgres user
if [ "$(id -u)" = '0' ]; then
	exec su-exec postgres "${BASH_SOURCE[0]}" "$@"
fi

if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
	docker_verify_minimum_env
	docker_init_database_dir
	pg_setup_hba_conf

	# only required for '--auth[-local]=md5' on POSTGRES_INITDB_ARGS
	export PGPASSWORD="${PGPASSWORD:-$POSTGRES_PASSWORD}"

	docker_temp_server_start "$@" -c max_locks_per_transaction=256
	docker_setup_db
	docker_process_init_files /docker-entrypoint-initdb.d/*
	docker_temp_server_stop
fi

# Always run the files in /always-initdb.d/
docker_temp_server_start "$@"
docker_process_init_files /always-initdb.d/*
docker_temp_server_stop

exec postgres "$@"