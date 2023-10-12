#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"

# The base setup is started before any test is executed and tore down after the
# last test finishes. In other words, all tests in this file run against the same
# base instance.

setup_file() {
    docker pull hivemq/mqtt-cli:4.15.0
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml -f tests/docker-compose.auth-test.yml up -d --build
    sleep 15
}

teardown_file() {
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml down --remove-orphans
    docker container prune -f && docker volume prune -af
}

@test "AUTH: token generation with ok params" {

    run curl -X POST --fail-with-body --location --silent localhost/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "param1=value1&param2=value2&acl=dangerous"

    assert_equal "$status" 0

    echo "$output"

    jwt_as_json=$(echo "$output" | jwt decode -j -)

    # For debug
    echo "$jwt_as_json"

    field=$(echo "$jwt_as_json" | jq .header.typ)
    assert_equal "$field" '"JWT"'

    field=$(echo "$jwt_as_json" | jq .header.alg)
    assert_equal "$field" '"HS256"'

    field=$(echo "$jwt_as_json" | jq .payload.iss)
    assert_equal "$field" '"pontos-hub"'

    field=$(echo "$jwt_as_json" | jq .payload.role)
    assert_equal "$field" '"web_user"'

    field=$(echo "$jwt_as_json" | jq .payload.param1)
    assert_equal "$field" '"value1"'

    field=$(echo "$jwt_as_json" | jq .payload.param2)
    assert_equal "$field" '"value2"'

    # Check that field with the name acl gets overwritten appropriately
    field=$(echo "$jwt_as_json" | jq .payload.sub)
    assert_equal "$field" '"__token__"'

    # Check that field with the name acl gets overwritten appropriately
    field=$(echo "$jwt_as_json" | jq .payload.acl)
    assert_equal "$field" '""'
}

@test "AUTH: token generation with non-allowed params" {

    run curl -X POST --fail-with-body --location localhost/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "param1=value1&not=allowed"

    assert_equal "$status" 22
    assert_line --partial 'The requested URL returned error: 400'
    assert_line --partial 'You provided: not param1 which is not a subset of the allowed ones: param1 param2 param3 acl'

}

@test "AUTH: token generation without required params" {

    run curl -X POST --fail-with-body --location localhost/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "param2=value2"

    assert_equal "$status" 22
    assert_line --partial 'The requested URL returned error: 400'
    assert_line --partial 'You provided: param2 which is not a superset of the required ones: param1'

}