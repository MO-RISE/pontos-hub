#!/bin/bash

# Install shell2http
wget -q -O - https://github.com/msoap/shell2http/releases/download/v1.16.0/shell2http_1.16.0_linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin shell2http

# Install jwt-cli
wget -q -O - https://github.com/mike-engel/jwt-cli/releases/download/5.0.3/jwt-linux.tar.gz | sudo tar xvz -C /usr/local/bin jwt