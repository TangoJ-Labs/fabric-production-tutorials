#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# Parse commandline args
MODE=$1;shift

echo "SHUTTING DOWN HYPERLEDGER FABRIC NETWORKS"

# # NOTE: REMOVING THE CONTAINERS WILL DELETE LEDGERS

# #Delete any ledger backups
# docker run -v $PWD:/tmp/first-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/first-network/ledgers-backup

#DELETE chaincode CONTAINERS
# docker stop $(docker ps -aq)
docker ps -aq | xargs -n 1 docker stop
# docker rm $(docker ps -a)
docker ps -aq | xargs -n 1 docker rm -v
CONTAINER_IDS=$(docker ps -aq)
if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
else
    docker rm -f $CONTAINER_IDS
fi

# NOTE: When only removing a chaincode container, see docs: https://hyperledger-fabric.readthedocs.io/en/latest/chaincode4noah.html#stop-and-start
# docker rm -f <container id>
# rm /var/hyperledger/production/chaincodes/<ccname>:<ccversion>

docker volume prune
docker network prune

#DELETE IMAGES
DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer*/) {print $3}')
if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
else
    docker rmi -f $DOCKER_IMAGE_IDS
fi

# verify results
docker ps -a
docker volume ls
docker network list
docker image list

# Don't remove the generated artifacts unless deleting network
if [ "$MODE" == "delete" ]; then
    echo "DELETING HLF GENERATED RESOURCES"
    
    # DELETE FILES
    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config ./org3-artifacts/crypto-config/ channel-artifacts/org3.json
    # remove the docker-compose yaml file that was customized to the example
    rm -f docker-compose-e2e.yaml

    # verify results
    ls -l
fi