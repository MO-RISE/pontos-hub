#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"

# The base setup is started before any test is executed and tore down after the
# last test finishes. In other words, all tests in this file run against the same
# base instance.

setup_file() {
    docker pull hivemq/mqtt-cli:4.15.0
    docker compose -f docker-compose.base.yml up -d
    sleep 10
}

teardown_file() {
    docker compose -f docker-compose.base.yml down --remove-orphans
    docker container prune -f && docker volume prune -f
}


@test "BASE: openAPI access" {

    run curl --silent localhost/api

    assert_equal "$status" 0
    assert_output --partial 'Welcome to the REST API documentation for PONTOS HUB!'

    actual=$(echo "$output" | jq '.basePath')
    assert_equal "$actual" '"/api"'
}

@test "BASE: docs access" {

    run curl -vv --location --silent localhost/api/docs

    assert_equal "$status" 0
    assert_output --partial '200 OK'
}

@test "BASE: REST API access" {

    run curl --silent localhost/api/vessel_ids
    assert_equal "$status" 0
    assert_output --partial 'example_vessel'

}

@test "BASE: mqtt subscribe access" {
    # We should be able to subscribe to anything
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'received SUBACK MqttSubAck{reasonCodes=[GRANTED_QOS_2]'
}

@test "BASE: mqtt publish access" {
    # We should be able to publish to anything
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything -m "Hello World!"
    assert_line --partial 'received PUBLISH acknowledgement'
}

@test "BASE: mqtt ingestion" {
    # Publish an actual payload that should be picked up by the ingestor and check that it gets written to the database
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -ws -ws:path mqtt -t PONTOS/test_vessel/test_parameter/1 -m '{"timestamp": 12345678, "value": 42}'
    assert_line --partial 'received PUBLISH acknowledgement'

    sleep 6

    run curl --silent localhost/api/vessel_ids
    assert_equal "$status" 0
    assert_output --partial 'test_vessel'
}