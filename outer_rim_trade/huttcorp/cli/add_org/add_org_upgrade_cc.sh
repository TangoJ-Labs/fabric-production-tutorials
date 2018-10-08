#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

######################################################################
########################### Update Channel ###########################
######################################################################

# Set env vars & enroll ORG ADMIN
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# Create update envelope and copy to shared directory
. /etc/hyperledger/fabric/setup/add_org/add_org_config.sh

# HAVE OTHER EXISTING ORG ADMINS SIGN IF NEEDED, THEN FINAL EXISTING ORG ADMIN:
peer channel update -f update_in_envelope.pb -c spicechannel $ORDERER_CONN_ARGS
# Sleep to finish any residual processes
sleep 3


######################################################################
########################## Upgrade Chaincode #########################
######################################################################

########################## Wallet Chaincode ##########################
# Install chaincode on all endorsing peers (iterate the version)
peer chaincode install -n ccWallet -p chaincode/wallet -v 2.0
# Sleep to allow the ledger to be updated
sleep 3

# Upgrade the chaincode - use the same version as the chaincode just installed
# USE ".member" NOT ".peer" - NodeOUs needed to use ".peer", ".client", etc
# peer chaincode upgrade -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member','cloudcityincMSP.member')" $ORDERER_CONN_ARGS -v 2.0
peer chaincode upgrade -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.peer','cloudcityincMSP.peer')" $ORDERER_CONN_ARGS -v 2.0
# Sleep to allow the ledger to be updated
sleep 3


########################### User Chaincode ###########################
# Install chaincode on peer (iterate the version)
peer chaincode install -n ccUser -p chaincode/user -v 2.0
# Sleep to allow the ledger to be updated
sleep 3

# Upgrade the chaincode - use the same version as the chaincode just installed
# USE ".member" NOT ".peer" - NodeOUs needed to use ".peer", ".client", etc
# peer chaincode upgrade -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member','cloudcityincMSP.member')" $ORDERER_CONN_ARGS -v 2.0
peer chaincode upgrade -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.peer','cloudcityincMSP.peer')" $ORDERER_CONN_ARGS -v 2.0
# Sleep to allow the ledger to be updated
sleep 3


########################### Chaincode Test ###########################
peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","Jabba"]}'
