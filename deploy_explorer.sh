#!/bin/bash

# Copyright Tecnalia Research & Innovation (https://www.tecnalia.com)
# Copyright Tecnalia Blockchain LAB
#
# SPDX-License-Identifier: Apache-2.0

#BASH CONFIGURATION
# Enable colored log
export TERM=xterm-256color
VERSION=1.1.0
export CRYPTO_CONFIG=${CRYPTO_CONFIG}
if [[ -z ${CRYPTO_CONFIG} ]]; then
    echo "ERROR: CRYPTO_CONFIG NOT DEFINED! Point CRYPTO_CONFIG to crypto-config location"
    exit 1
fi

export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")
export MARCH=$(uname -m)
export FABRIC_TAG=${MARCH}-${VERSION}
export CA_TAG=${MARCH}-${VERSION}
BINARY_FILE=hyperledger-fabric-${ARCH}-${VERSION}.tar.gz
CA_BINARY_FILE=hyperledger-fabric-ca-${ARCH}-${VERSION}.tar.gz

function banner(){
	echo ""
	echo "  _    _                       _          _                   ______            _                     "
	echo " | |  | |                     | |        | |                 |  ____|          | |                    "
	echo " | |__| |_   _ _ __   ___ _ __| | ___  __| | __ _  ___ _ __  | |__  __  ___ __ | | ___  _ __ ___ _ __ "
	echo " |  __  | | | | '_ \ / _ \ '__| |/ _ \/ _\` |/ _\` |/ _ \ '__| |  __| \ \/ / '_ \| |/ _ \| '__/ _ \ '__|"
	echo " | |  | | |_| | |_) |  __/ |  | |  __/ (_| | (_| |  __/ |    | |____ >  <| |_) | | (_) | | |  __/ |   "
	echo " |_|  |_|\__, | .__/ \___|_|  |_|\___|\__,_|\__, |\___|_|    |______/_/\_\ .__/|_|\___/|_|  \___|_|   "
	echo "          __/ | |                            __/ |                       | |                          "
	echo "         |___/|_|                           |___/                        |_|                          "
	echo ""
}

# HELPER FUNCTIONS
# Check whether a given container (filtered by name) exists or not
function existsContainer(){
	containerName=$1
	if [ -n "$(docker ps -aq -f name=$containerName)" ]; then
	    return 0 #true
	else
		return 1 #false
	fi
}

# HELPER FUNCTIONS
# Check whether a given network (filtered by name) exists or not
function existsNetwork(){
	networkName=$1
	if [ -n "$(docker network ls -q -f name=$networkName)" ]; then
	    return 0 #true
	else
		return 1 #false
	fi
}

# Check whether a given network (filtered by name) exists or not
function existsImage(){
	imageName=$1
	if [ -n "$(docker images -a -q $imageName)" ]; then
	    return 0 #true
	else
		return 1 #false
	fi
}

# Configure settings of HYPERLEDGER EXPLORER
function config(){
	# BEGIN: GLOBAL VARIABLES OF THE SCRIPT
	defaultFabricName="net1"
	if [ -n "$1" ]; then
		echo "No custom Hyperledger Network configuration supplied. Using default network name: $defaultFabricName"
		fabricBlockchainNetworkName=$defaultFabricName
	else
		fabricBlockchainNetworkName=$1
		echo "Using custom Hyperledger Network configuration. Network name: $fabricBlockchainNetworkName"
	fi
	docker_network_name="fabric-explorer-net"
	# Default Hyperledger Explorer Database Credentials.
	explorer_db_user="hppoc"
	explorer_db_pwd="password"
	explorer_db_name="fabricexplorer"
	#configure explorer to connect to specific Blockchain network using given configuration
	network_config_file=$(pwd)/config.json
	#configure explorer to connect to specific Blockchain network using given crypto materials
	network_crypto_base_path=${CRYPTO_CONFIG}

	# local vnet configuration

	# Docker network configuration
	# Address:   192.168.10.0         11000000.10101000.00001010. 00000000
	# Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
	# Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
	# =>
	# Network:   192.168.10.0/24      11000000.10101000.00001010. 00000000
	# HostMin:   192.168.10.1         11000000.10101000.00001010. 00000001
	# HostMax:   192.168.10.254       11000000.10101000.00001010. 11111110
	# Broadcast: 192.168.10.255       11000000.10101000.00001010. 11111111
	# Hosts/Net: 254                   Class C, Private Internet
	subnet=192.168.10.0/24

	# database container configuration
	fabric_explorer_db_tag="hyperledger-blockchain-explorer-db"
	fabric_explorer_db_name="blockchain-explorer-db"
	db_ip=192.168.10.11

	# fabric explorer configuratio
	fabric_explorer_tag="hyperledger-blockchain-explorer"
	fabric_explorer_name="blockchain-explorer"
	explorer_ip=192.168.10.12
	# END: GLOBAL VARIABLES OF THE SCRIPT
}

function deploy_prepare_network(){
	if existsNetwork $docker_network_name; then
		echo "Removing old configured docker vnet for Hyperledger Explorer"
		# to avoid active endpoints
		stop_database
		stop_explorer
		docker network rm $docker_network_name
	fi

	echo "Creating default Docker vnet for Hyperledger Fabric Explorer"
	docker network create --subnet=$subnet $docker_network_name
}

function deploy_build_database(){
	echo "Building Hyperledger Fabric Database image from current local version..."
	docker build -f postgres-Dockerfile --tag $fabric_explorer_db_tag .
}

function stop_database(){
	if existsContainer $fabric_explorer_db_name; then
		echo "Stopping previously deployed Hyperledger Fabric Explorer DATABASE instance..."
		docker stop $fabric_explorer_db_name && \
		docker rm $fabric_explorer_db_name
	fi
}

function deploy_run_database(){
	stop_database

	# deploy database with given user/password configuration
	# By default, since docker is used, there are no users created so default available user is
	# postgres/password
	echo "Deploying Database (POSTGRES) container at $db_ip"
	docker run \
		-d \
		--name $fabric_explorer_db_name \
		--net $docker_network_name --ip $db_ip \
		-e DATABASE_DATABASE=$explorer_db_name \
		-e DATABASE_USERNAME=$explorer_db_user \
		-e DATABASE_PASSWORD=$explorer_db_pwd \
		-p 5432:5432 \
		$fabric_explorer_db_tag
}

function deploy_load_database(){
	echo "Preparing database for Explorer"
	echo "Waiting...6s"
	sleep 1s
	echo "Waiting...5s"
	sleep 1s
	echo "Waiting...4s"
	sleep 1s
	echo "Waiting...3s"
	sleep 1s
	echo "Waiting...2s"
	sleep 1s
	echo "Waiting...1s"
	sleep 1s
	echo "Creating default database schemas..."
	docker exec $fabric_explorer_db_name /opt/createdb.sh
}

function deploy_build_explorer(){
	echo "Building Hyperledger Fabric explorer image from current local version..."
	docker build --tag $fabric_explorer_tag .
	echo "Hyperledger Fabric network configuration file isd at $network_config_file"
	echo "Hyperledger Fabric network crypto material at $network_crypto_base_path"
}

function stop_explorer(){
	if existsContainer $fabric_explorer_name; then
		echo "Stopping previously deployed Hyperledger Fabric Explorer instance..."
		docker stop $fabric_explorer_name && \
		docker rm $fabric_explorer_name
	fi
}

function deploy_run_explorer(){
	stop_explorer

	echo "Deploying Hyperledger Fabric Explorer container at $explorer_ip"
	docker run \
		-d \
		--name $fabric_explorer_name \
		--net $docker_network_name --ip $explorer_ip \
		-e DATABASE_HOST=$db_ip \
		-e DATABASE_USERNAME=$explorer_db_user \
		-e DATABASE_PASSWD=$explorer_db_pwd \
		-e CONFIG_CP=/opt/explorer/config.json \
		-v $network_crypto_base_path:/tmp/crypto \
		-p 8080:8080 \
		hyperledger-blockchain-explorer
}

function connect_to_network(){
	echo "Trying to join to existing network $1"
	docker network connect $1 $(docker ps -qf name=^/$fabric_explorer_name$)
	docker network connect $1 $(docker ps -qf name=^/$fabric_explorer_db_name$)
}

function dbOnly(){

    echo "Starting explorer in local mode..."
	if !(existsImage $fabric_explorer_db_tag); then
		deploy_build_database
	fi
	deploy_run_database
	deploy_load_database

}
function deploy(){
	echo "Inside deploy $2"
	if [ -n "$2" ]; then
		echo "deploying network test"
		deploy_prepare_network
	fi

    dbOnly

	if !(existsImage $fabric_explorer_tag); then
		deploy_build_explorer
	fi
	deploy_run_explorer

	if [ -n "$2" ]; then
		connect_to_network $2
	fi
}

# Incrementally downloads the .tar.gz file locally first, only decompressing it
# after the download is complete. This is slower than binaryDownload() but
# allows the download to be resumed.
binaryIncrementalDownload() {
      local BINARY_FILE=$1
      local URL=$2
      curl -f -s -C - ${URL} -o ${BINARY_FILE} || rc=$?
      # Due to limitations in the current Nexus repo:
      # curl returns 33 when there's a resume attempt with no more bytes to download
      # curl returns 2 after finishing a resumed download
      # with -f curl returns 22 on a 404
      if [ "$rc" = 22 ]; then
	  # looks like the requested file doesn't actually exist so stop here
	  return 22
      fi
      if [ -z "$rc" ] || [ $rc -eq 33 ] || [ $rc -eq 2 ]; then
          # The checksum validates that RC 33 or 2 are not real failures
          echo "==> File downloaded. Verifying the md5sum..."
          localMd5sum=$(md5sum ${BINARY_FILE} | awk '{print $1}')
          remoteMd5sum=$(curl -s ${URL}.md5)
          if [ "$localMd5sum" == "$remoteMd5sum" ]; then
              echo "==> Extracting ${BINARY_FILE}..."
              tar xzf ./${BINARY_FILE} --overwrite
	      echo "==> Done."
              rm -f ${BINARY_FILE} ${BINARY_FILE}.md5
          else
              echo "Download failed: the local md5sum is different from the remote md5sum. Please try again."
              rm -f ${BINARY_FILE} ${BINARY_FILE}.md5
              exit 1
          fi
      else
          echo "Failure downloading binaries (curl RC=$rc). Please try again and the download will resume from where it stopped."
          exit 1
      fi
}

# This will attempt to download the .tar.gz all at once, but will trigger the
# binaryIncrementalDownload() function upon a failure, allowing for resume
# if there are network failures.
binaryDownload() {
      local BINARY_FILE=$1
      local URL=$2
      echo "===> Downloading: " ${URL}
      # Check if a previous failure occurred and the file was partially downloaded
      if [ -e ${BINARY_FILE} ]; then
          echo "==> Partial binary file found. Resuming download..."
          binaryIncrementalDownload ${BINARY_FILE} ${URL}
      else
          curl ${URL} | tar xz || rc=$?
          if [ ! -z "$rc" ]; then
              echo "==> There was an error downloading the binary file. Switching to incremental download."
              echo "==> Downloading file..."
              binaryIncrementalDownload ${BINARY_FILE} ${URL}
	  else
	      echo "==> Done."
          fi
      fi
}

binariesInstall() {
  echo "===> Downloading version ${FABRIC_TAG} platform specific fabric binaries"
  binaryDownload ${BINARY_FILE} https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/${ARCH}-${VERSION}/${BINARY_FILE}
  if [ $? -eq 22 ]; then
     echo
     echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
     echo
   fi

  echo "===> Downloading version ${CA_TAG} platform specific fabric-ca-client binary"
  binaryDownload ${CA_BINARY_FILE} https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca/${ARCH}-${VERSION}/${CA_BINARY_FILE}
  if [ $? -eq 22 ]; then
     echo
     echo "------> ${CA_TAG} fabric-ca-client binary is not available to download  (Available from 1.1.0-rc1) <----"
     echo
   fi
}
function down(){
    stop_explorer
    stop_database
}

function generateCP(){
    CHANNEL=${CHANNEL:-foo}
    #generate cp in docker network
    sed -e 's|%CRYPTO_CONFIG%|/tmp/crypto|g' \
        -e 's|%HLFBIN1_1%|/opt/explorer/bin|g' \
        -e 's|%CHANNEL%|'${CHANNEL}'|g' \
        connection-profile-docker.json.template > config.json
}

function main(){
	banner
	#Pass arguments to function exactly as-is
	config "$@"

    if [ ! -d "./bin" ]; then
        binariesInstall
    fi

	MODE=$1;
    if [ "$MODE" == "--down" ]; then
	    echo "Stopping Hyperledger Fabric explorer containers..."
        down
    elif [ "$MODE" == "--clean" ]; then
	    echo "Cleaning Hyperledger Fabric explorer images..."
        down
        docker rmi $(docker images -q ${fabric_explorer_db_tag})
        docker rmi $(docker images -q ${fabric_explorer_tag})
    elif [ "$MODE" == "--dbonly" ]; then
        echo "Deploying database only"
        dbOnly
    else
        generateCP
        deploy "$@"
    fi
}
echo "$@"
#Pass arguments to function exactly as-is
main "$@"
#binariesInstall
