#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"

# setup() {
#     REPO_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )"/.. >/dev/null 2>&1 && pwd )"
# }

teardown() {
    docker compose -f docker-compose.base.yml down --remove-orphans
    docker container prune -f && docker volume prune -f
}


@test "API access" {
    bats_require_minimum_version 1.5.0

    docker compose -f docker-compose.base.yml up -d

    sleep 10

    run curl localhost/api

    assert_equal "$status" 0

}