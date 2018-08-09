#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0
#

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

#######################################################################
############################## JOIN CHANNEL ###########################

# Move to the directory mapped to the local dir with the files needed
# cd /etc/hyperledger/fabric/setup

# Set env vars & enroll ORG ADMIN
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# # Get the genesis block into org2 dir
# Fetch channel config block from orderer
peer channel fetch 0 mychannel.block -c mychannel $ORDERER_CONN_ARGS

# Join sometimes fails - try a few times if needed
peer channel join -b mychannel.block


#######################################################################
########################### INSTALL CHAINCODE #########################

# Install the chaincode - ensure that the version option matches
# the other org chaincode install
peer chaincode install -n mycc -v 2.0 -l golang -p github.com/hyperledger/fabric-samples/chaincode/abac/go

################################# TEST ################################
# Check query & invoke
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS
# Sleep to allow the ledger to be updated
sleep 3000
# Query again to check
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
