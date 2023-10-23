#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"


# In this file, no automatic setup is configured, a teardown is provided though,
# to make sure all tests leave a clean slate

teardown() {
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml down --remove-orphans
    docker container prune -f && docker volume prune -af
    git checkout -- broker/acl.conf
}

@test "AUTH: Custom acl rules" {

    # Read original config
    original_rules=$(cat broker/acl.conf)

    # Generate some  new rules
    custom_rules=$(bash scripts/generate_publish_acl_rules.sh -t PONTOS_INGRESS -s /+ -u test_user -v test_vessel -p test_parameter)

    # Prepend and replace original conf file
    (echo "$custom_rules"; echo "$original_rules") > broker/acl.conf

    cat broker/acl.conf

    # Start base setup
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml up -d --build
    sleep 15

    # Lets generate a token by ourselves with subject 'test_user'
    token=$(jwt encode --sub=test_user --secret="$PONTOS_JWT_SECRET")

    # Publish an actual payload that should be picked up by the ingestor and check that it gets written to the database
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u 'test_user' -pw "$token" -ws -ws:path mqtt -t PONTOS_INGRESS/test_vessel/test_parameter/1 -m '{"timestamp": 12345678, "value": 42}'
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'received PUBLISH acknowledgement'
    # And we should not be kicked out!
    refute_line --partial 'DISCONNECTED Server closed connection without DISCONNECT.'

    sleep 6

    # And generate a proper token with all claims necessary to access the api
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    token="$output"

    run curl --silent localhost/api/vessel_ids \
        -H "Authorization: Bearer ${token}"
    assert_equal "$status" 0
    assert_output --partial 'test_vessel'

}

@test "AUTH: Topic rewrite" {

    # Read original config
    original_rules=$(cat broker/acl.conf)

    # Generate some  new rules with the old ingress topic root (PONTOS)
    custom_rules=$(bash scripts/generate_publish_acl_rules.sh -t PONTOS -s /+ -u test_user -v test_vessel -p test_parameter)

    # Prepend and replace original conf file
    (echo "$custom_rules"; echo "$original_rules") > broker/acl.conf

    cat broker/acl.conf

    # Start base setup with additional conf for topic rewrite for EMQX
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml -f tests/docker-compose.auth-topic-rewrite.yml up -d --build
    sleep 15

    # Lets generate a token by ourselves with subject 'test_user'
    token=$(jwt encode --sub=test_user --secret="$PONTOS_JWT_SECRET")

    # Publish an actual payload on the old PONTOS root topic that should be picked up by the ingestor and check that it gets written to the database
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u 'test_user' -pw "$token" -ws -ws:path mqtt -t PONTOS/test_vessel/test_parameter/1 -m '{"timestamp": 12345678, "value": 42}'
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'received PUBLISH acknowledgement'
    # And we should not be kicked out!
    refute_line --partial 'DISCONNECTED Server closed connection without DISCONNECT.'

    sleep 6

    # And generate a proper token with all claims necessary to access the api
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    token="$output"

    run curl --silent localhost/api/vessel_ids \
        -H "Authorization: Bearer ${token}"
    assert_equal "$status" 0
    assert_output --partial 'test_vessel'

}