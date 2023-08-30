#!/bin/bash

# Install shell2http
wget -q -O - https://github.com/msoap/shell2http/releases/download/v1.16.0/shell2http_1.16.0_linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin shell2http

# Install jwt-cli
wget -q -O - https://github.com/mike-engel/jwt-cli/releases/download/5.0.3/jwt-linux.tar.gz | sudo tar xvz -C /usr/local/bin jwt

# Install bats helpers
[ -d tests/bats-helpers ] && rm -rf tests/bats-helpers && mkdir -p tests/bats-helpers

TARGET_DIRECTORY="tests/bats-helpers/bats-support"
mkdir -p ${TARGET_DIRECTORY}
wget -q -O - https://github.com/bats-core/bats-support/archive/refs/tags/v0.3.0.tar.gz | tar xvz --strip-components=1 --overwrite -C ${TARGET_DIRECTORY}

TARGET_DIRECTORY="tests/bats-helpers/bats-assert"
mkdir -p ${TARGET_DIRECTORY}
wget -q -O - https://github.com/bats-core/bats-assert/archive/refs/tags/v2.1.0.tar.gz | tar xvz --strip-components=1 --overwrite -C ${TARGET_DIRECTORY}

TARGET_DIRECTORY="tests/bats-helpers/bats-file"
mkdir -p ${TARGET_DIRECTORY}
wget -q -O - https://github.com/bats-core/bats-file/archive/refs/tags/v0.4.0.tar.gz | tar xvz --strip-components=1 --overwrite -C ${TARGET_DIRECTORY}
