#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"

# The base setup is started before any test is executed and tore down after the
# last test finishes. In other words, all tests in this file run against the same
# base instance.

setup_file() {
    docker pull hivemq/mqtt-cli:4.15.0
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml up -d --build
    sleep 15
}

teardown_file() {
    docker compose -f docker-compose.base.yml -f docker-compose.auth.yml down --remove-orphans
    docker container prune -f && docker volume prune -af
}


@test "AUTH: openAPI access" {

    # We should still have access to the api docs which sits at the /api root

    run curl --silent localhost/api

    assert_equal "$status" 0
    assert_output --partial 'Welcome to the REST API documentation for PONTOS HUB!'

    actual=$(echo "$output" | jq '.basePath')
    assert_equal "$actual" '"/api"'
}

@test "AUTH: docs access" {

    # Same here, we should still have access to the docs.

    run curl -vv --location --silent localhost/api/docs

    assert_equal "$status" 0
    assert_output --partial '200 OK'
}

@test "AUTH: REST API access" {

    # Should not work as-is
    run curl --silent localhost/api/vessel_ids
    assert_equal "$status" 0
    assert_output --partial 'permission denied for view vessel_ids'

    # Lets generate a token
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    token="$output"

    # Now we should have access
    run curl -vv --silent localhost/api/vessel_ids \
        -H "Authorization: Bearer ${token}"
    assert_equal "$status" 0
    assert_output --partial '200 OK'

}

@test "AUTH: mqtt subscribe access" {

    # We should NOT be able to connect whatsoever since we dont provide a token
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'DISCONNECTED CONNECT failed as CONNACK contained an Error Code: NOT_AUTHORIZED.'

    # Not even when we try to subcribe to the PONTOS root topic
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -ws -ws:path mqtt -t PONTOS_EGRESS/#
    assert_line --partial 'DISCONNECTED CONNECT failed as CONNACK contained an Error Code: NOT_AUTHORIZED.'

    # Lets generate a token
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    token="$output"

    # Now, connection should be successful but we should be kicked out when trying to subscribe to anything
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -u '__token__' -pw "$token" -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial "failed SUBSCRIBE to TOPIC 'anything/anything/#': Server closed connection without DISCONNECT."

    # However, we should be allowed to subscribe to the PONTOS root topic
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -u '__token__' -pw "$token" -ws -ws:path mqtt -t PONTOS_EGRESS/#
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'received SUBACK MqttSubAck{reasonCodes=[GRANTED_QOS_2]'

    # But, if we give the wrong username, we should not be allowed access
    run timeout --preserve-status 5s docker run --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -u 'wrong' -pw "$token" -ws -ws:path mqtt -t anything/anything/#
    assert_line --partial 'DISCONNECTED CONNECT failed as CONNACK contained an Error Code: BAD_USER_NAME_OR_PASSWORD.'
}

@test "AUTH: mqtt publish access" {

    # We should NOT be able to connect whatsoever since we dont provide a token
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -ws -ws:path mqtt -t anything/anything -m "Hello World!"
    assert_line --partial 'DISCONNECTED CONNECT failed as CONNACK contained an Error Code: NOT_AUTHORIZED.'

    # Lets generate a token
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    token="$output"

    # Now, connection should be successful but we should be kicked out when trying to publish to ahything
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u '__token__' -pw "$token" -ws -ws:path mqtt -t anything/anything -m "Hello World!"
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'DISCONNECTED Server closed connection without DISCONNECT.'

    # Lets generate a token by ourselves to try out that publish acl works
    token=$(jwt encode --sub=__token__ --secret="$PONTOS_JWT_SECRET" '{"acl":{"pub": ["anything/anything"]}}')

    # Now, both connection and publish should be ok
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u '__token__' -pw "$token" -ws -ws:path mqtt -t anything/anything -m "Hello World!"
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'received PUBLISH acknowledgement'
    # And we should not be kicked out!
    refute_line --partial 'DISCONNECTED Server closed connection without DISCONNECT.'

}

@test "AUTH: mqtt ingestion" {

    # Lets generate a token by ourselves so that we are allowed to publish
    token=$(jwt encode --sub=__token__ --secret="$PONTOS_JWT_SECRET" '{"acl":{"pub": ["PONTOS_INGRESS/test_vessel/test_parameter/+"]}}')

    # Publish an actual payload that should be picked up by the ingestor and check that it gets written to the database
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u '__token__' -pw "$token" -ws -ws:path mqtt -t PONTOS_INGRESS/test_vessel/test_parameter/1 -m '{"timestamp": 12345678, "value": 42}'
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


@test "AUTH: mqtt editor" {

    # Lets generate a token for the publisher
    publisher_token=$(jwt encode --sub=__token__ --secret="$PONTOS_JWT_SECRET" '{"acl":{"pub": ["PONTOS_INGRESS/test_vessel/test_parameter/+"]}}')

    # And fetch one for the subscriber
    run curl -X POST --location --silent localhost/token
    assert_equal "$status" 0
    subscriber_token="$output"

    # Start a subscriber in the background and let it run for 10s
    docker run --name subscriber --detach --network='host' hivemq/mqtt-cli:4.15.0 sub -v -h localhost -p 80 -u '__token__' -pw "$subscriber_token" -ws -ws:path mqtt -t PONTOS_EGRESS/#

    # Publish an actual payload that should be rewritten by the mqtt editor
    run docker run --network='host' hivemq/mqtt-cli:4.15.0 pub -v -h localhost -p 80 -u '__token__' -pw "$publisher_token" -ws -ws:path mqtt -t PONTOS_INGRESS/test_vessel/test_parameter/1 -m '{"timestamp": 12345678, "value": 42}'
    assert_line --partial 'received CONNACK MqttConnAck{reasonCode=SUCCESS'
    assert_line --partial 'received PUBLISH acknowledgement'

    sleep 1

    run docker logs subscriber
    assert_line --partial '{"timestamp": 12345678, "value": 42}'

    docker kill subscriber
}
