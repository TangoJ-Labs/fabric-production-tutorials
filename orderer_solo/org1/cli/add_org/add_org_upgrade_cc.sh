#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0
#

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

#######################################################################
############################# UPDATE CHANNEL ##########################

# Set env vars & enroll ORG ADMIN
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# Create update envelope and copy to shared directory
. /etc/hyperledger/fabric/setup/add_org/add_org_config.sh

# HAVE OTHER EXISTING ORG ADMINS SIGN IF NEEDED, THEN FINAL EXISTING ORG ADMIN:
peer channel update -f update_in_envelope.pb -c mychannel $ORDERER_CONN_ARGS


#######################################################################
########################### UPGRADE CHAINCODE #########################

# Install the new chaincode (change the version)
peer chaincode install -n mycc -v 2.0 -l golang -p github.com/hyperledger/fabric-samples/chaincode/abac/go

# Upgrade the chaincode - use the same version as the chaincode just installed
# USE ".member" NOT ".peer" - need to figure out NodeOUs to use ".peer", ".client", etc
peer chaincode upgrade -C mychannel -n mycc -v 2.0 -c '{"Args":["init","a","5000","b","8000"]}' -P "OR('org1MSP.member','org2MSP.member')" $ORDERER_CONN_ARGS

################################# TEST ################################
# Check query & invoke
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS
# Sleep to allow the ledger to be updated
sleep 3000
# Query again to check
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
