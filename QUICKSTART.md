## Quick start guide to integrate bc-explorer and fab network. All commands are referenced from root of project

# Requirements

-nodejs 8.11.x

-docker

-xcode ( if using macos )

Deploy fabric network

# Steps to get started developing locally and running bc-explorer on your terminal

1. Start postgres server containerized

    arg1 = existing fabric network id
    
    Example

    ```bash
    ./deploy_explorer.sh --dbonly
    ```
    To shut down postgres
    
    ```bash
    ./deploy_explorer.sh --down
    ```
    
2.  Install all dependencies. Only need to be run once after cloning repo.

    ```bash
    npm install
    cd client/
    npm install
    npm run build
    ```
    
3.  Ensure correct connection-profile. By default, connection-profile.json.template is used to define min fabric network: orderer.example.com and peer0.org1.example.com with channel foo. Ensure network syncs up if you are using a different network.

4.  Run bc-explorer, ensure env CRYPTO_CONFIG is defined(reference networkup).

    CRYPTO_CONFIG=`<path to crypto-config containing ordererOrganizations and peerOrganizations>`
    
    Example:
    
    ```bash
    CRYPTO_CONFIG=/Users/any/project/crypto-config
    ```

    Will start blockchain explorer on your terminal, to run bc-explorer in the background 
    ```bash
    ./run.sh
    ```
    
    locate server at localhost:8080
    
    to shutdown server, ctrl+c

# To deploy bc-explorer in the background

1. to just deploy all containers ./deploy_explorer.sh net1 <name of current fab network>
./deploy_explorer --down to bring down

check deployment using docker ps