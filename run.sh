#!/usr/bin/env bash
set -x
ENVIRONMENT=${ENV:local}

if [[ $ENV = "dev" ]]; then

# Create config.json to be consumed by deploy.sh

export HLFBIN1_1=$(pwd)/bin

sed -e 's|%CRYPTO_CONFIG%|'$CRYPTO_CONFIG'|g' \
    -e 's|%HLFBIN1_1%|'$HLFBIN1_1'|g' \
    connection-profile.json.template > config.json
echo "created config.json"

else

#Local setup to run explorer with logs on terminal, ctrl+c to stop app

sed -e 's|%CRYPTO_CONFIG%|'$CRYPTO_CONFIG'|g' \
    -e 's|%HLFBIN1_1%|'$HLFBIN1_1'|g' \
    connection-profile.json.template > config.json

CONFIG_CP=$(pwd)/config.json node main.js

fi

set +x