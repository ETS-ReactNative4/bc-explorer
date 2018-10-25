#!/usr/bin/env bash

ENVIRONMENT=${ENV:local}

if [[ $ENV -eq "dev" ]]; then

export HLFBIN1_1=$(pwd)/bin

sed -e 's|%CRYPTO_CONFIG%|'$CRYPTO_CONFIG'|g' \
    -e 's|%HLFBIN1_1%|'$HLFBIN1_1'|g' \
    connection-profile.json.template > config.json

else

#Local setup to run explorer with logs on terminal, ctrl+c to stop app

sed -e 's|%CRYPTO_CONFIG%|'$CRYPTO_CONFIG'|g' \
    -e 's|%HLFBIN1_1%|'$HLFBIN1_1'|g' \
    connection-profile.json.template > config.json

CONFIG_CP=$(pwd)/config.json node main.js

fi
