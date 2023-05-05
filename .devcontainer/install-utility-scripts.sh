#!/bin/bash

## jwt-cli
wget -qO- https://github.com/mike-engel/jwt-cli/releases/download/5.0.3/jwt-linux.tar.gz \
    | sudo tar xvz -C /usr/local/bin \
    && sudo chmod +x /usr/local/bin/jwt