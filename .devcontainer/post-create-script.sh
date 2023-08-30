#!/bin/bash

# Install shell2http
wget -q -O - https://github.com/msoap/shell2http/releases/download/v1.16.0/shell2http_1.16.0_linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin shell2http

# Install jwt-cli
wget -q -O - https://github.com/mike-engel/jwt-cli/releases/download/5.0.3/jwt-linux.tar.gz | sudo tar xvz -C /usr/local/bin jwt

# Install bats helpers
[ -d tests/bats-helpers ] && rm -rf tests/bats-helpers && mkdir -p tests/bats-helpers

git clone --depth 1 https://github.com/bats-core/bats-support.git tests/bats-helpers/bats-support
git clone --depth 1 https://github.com/bats-core/bats-assert.git tests/bats-helpers/bats-assert
git clone --depth 1 https://github.com/bats-core/bats-file.git tests/bats-helpers/bats-file