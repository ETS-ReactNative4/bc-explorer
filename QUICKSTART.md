## Quick start guide to integrate bc-explorer and fab network. All commands are referenced from root of project

# Requirements

-nodejs 8.11.x

-docker

-xcode

# Steps to get started

1. Start postgres server containerized

    ```bash
    ./deploy_explorer.sh --dbonly
    ```
    To shut down postgres
    
    ```bash
    ./deploy_explorer.sh --down
    ```
    
2.  Install all dependencies. Only need to be run once.

    ```bash
    npm install
    cd client/
    npm install
    npm run build
    ```
    
3.  Ensure correct connection-profile. By default, connection-profile.json.template is used to define min fabric network: orderer.example.com and peer0.org1.example.com with channel foo. Ensure network syncs up if you are using a different network.

4.  Run bc-explorer, ensure env CRYPTO_CONFIG and HLBIN1_1 are defined(reference networkup).

    ```bash
    ./run.sh
    ```
    
    locate server at localhost:8080
    
    to shutdown server, ctrl+c
