#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"


# In this file, no automatic setup is configured, a teardown is provided though,
# to make sure all tests leave a clean slate

teardown() {
    docker compose -f docker-compose.base.yml down --remove-orphans
    docker container prune -f && docker volume prune -f
}

@test "BASE: MQTT retain persistence across reboots" {

    # Start base setup
    docker compose -f docker-compose.base.yml up -d
    sleep 10

    # Publish something with retain=true
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything -m "Hello World!" --retain
    assert_line --partial 'received PUBLISH acknowledgement'

    # Subscribe and check that we receive the retained message
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'received SUBACK MqttSubAck{reasonCodes=[GRANTED_QOS_2]'
    assert_line --partial 'Hello World!'

    # down and up
    docker compose -f docker-compose.base.yml down
    docker compose -f docker-compose.base.yml up -d
    sleep 10

    # Subscribe again and check that we receive the retained message
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'received SUBACK MqttSubAck{reasonCodes=[GRANTED_QOS_2]'
    assert_line --partial 'Hello World!'

}