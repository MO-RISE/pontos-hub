#!/usr/bin/env bats

load "./bats-helpers/bats-support/load"
load "./bats-helpers/bats-assert/load"
load "./bats-helpers/bats-file/load"

# This file deploys the latest, tagged release of pontos-hub and then tries to upgrade to the current commit.

setup() {
    repo_root="$( cd "$( dirname "$BATS_TEST_FILENAME" )"/.. >/dev/null 2>&1 && pwd )"
    clone_dir="$(temp_make)"
    deploy_dir="$(temp_make)"
}

teardown() {
    docker compose -f docker-compose.base.yml down --remove-orphans
    docker container prune -f && docker volume prune -f
    rm -rf "$clone_dir"
    rm -rf "$deploy_dir"
}

@test "BASE: Test migration" {

    # Find latest proper release and clone it into a temporary directory
    latest_release=$(git describe --tags --abbrev=0)
    echo "Testing migration from ${latest_release}"
    git clone --depth 1 --branch "${latest_release}" 'https://github.com/MO-RISE/pontos-hub.git' "$clone_dir"

    # Create a symlink to a common deploy directory
    rm -rf "$deploy_dir"
    ln -sf "$clone_dir" "$deploy_dir"

    # Deploy using latest released tag
    cd "$deploy_dir"
    docker compose -f docker-compose.base.yml up -d
    sleep 10

    # Kill (without pruning the data)
    docker compose -f docker-compose.base.yml down --remove-orphans && docker container prune -f

    # Remove symlink and create new symlink to the current commit to be tested
    rm -rf "$deploy_dir"
    ln -sf "$repo_root" "$deploy_dir"

    # Deploy using the current commit to be tested
    cd "$deploy_dir"
    docker compose -f docker-compose.base.yml up -d
    sleep 10
    docker compose -f docker-compose.base.yml logs

    # Perform some checks
    run curl --silent localhost/api/vessel_ids
    assert_equal "$status" 0

}

