#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

######################################################################
############################ Join Channel ############################
######################################################################

# Move to the directory mapped to the local dir with the files needed
# cd /etc/hyperledger/fabric/setup

# Set env vars & enroll ORG ADMIN
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# # Get the genesis block into cloudcityinc dir
# Fetch channel config block from orderer
peer channel fetch 0 spicechannel.block -c spicechannel $ORDERER_CONN_ARGS
# Sleep to finish any residual processes
sleep 3

# Join sometimes fails - try a few times if needed
peer channel join -b spicechannel.block
# Sleep to finish any residual processes
sleep 3



######################################################################
######################### Install Chaincode ##########################
######################################################################

########################## Wallet Chaincode ##########################
# Install the chaincode - ensure that the version option matches
# the other org chaincode install
peer chaincode install -n ccWallet -p chaincode/wallet -v 2.0
# Sleep to allow the ledger to be updated
sleep 3

# No need to instantiate the chaincode - it will be started on the peer when needed


########################### User Chaincode ###########################
# Install the chaincode - ensure that the version option matches
# the other org chaincode install
peer chaincode install -n ccUser -p chaincode/user -v 2.0
# Sleep to allow the ledger to be updated
sleep 3

# No need to instantiate the chaincode - it will be started on the peer when needed


########################### Chaincode Test ###########################
peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["create","CloudCity"]}'
# Sleep to allow the ledger to be updated
sleep 3

peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["deposit","CloudCity","10000000"]}'
# Sleep to allow the ledger to be updated
sleep 3

peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","CloudCity"]}'
