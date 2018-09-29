#!/bin/bash


# Execute inside the CLI container (docker exec -it huttcorp-cli bash):

source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

######################################################################
########################### Create Channel ###########################
######################################################################

# Create the Channel
# this will create the block to send with the join command
peer channel create --logging-level=DEBUG -c spicechannel -f $FABRIC_CFG_PATH/channel.tx $ORDERER_CONN_ARGS
# Sleep to finish any residual processes
sleep 3

# Have the peer join the channel - use the block created from the "peer channel create" command (probably saved in same directory where create command was issued)
peer channel join -b spicechannel.block
# Sleep to finish any residual processes
sleep 3

# Update the anchor peers (FOR ANCHOR PEERS ONLY)
peer channel update -c spicechannel -f $FABRIC_CFG_PATH/huttcorp-anchors.tx $ORDERER_CONN_ARGS
# Sleep to finish any residual processes
sleep 3


######################################################################
######################### Install Chaincode ##########################
######################################################################

########################## Wallet Chaincode ##########################
# Install chaincode on all endorsing peers
peer chaincode install -n ccWallet -p chaincode/wallet -v 1.0
# Sleep to allow the ledger to be updated
sleep 3

# Instantiate chaincode on peer(s) with chaincode installed
peer chaincode instantiate -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.0
# Sleep to allow the ledger to be updated
sleep 3


########################### User Chaincode ###########################
# Install chaincode on peer
peer chaincode install -n ccUser -p chaincode/user -v 1.0
# Sleep to allow the ledger to be updated
sleep 3

# Instantiate chaincode on peer(s) with chaincode installed
peer chaincode instantiate -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.0
# Sleep to allow the ledger to be updated
sleep 3


########################### Chaincode Test ###########################
# Prep the Wallet ledger with some default accounts (to demo the SDK)

peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["create","Jabba"]}'
# Sleep to allow the ledger to be updated
sleep 3

peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["deposit","Jabba","1000000"]}'
# Sleep to allow the ledger to be updated
sleep 3

peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","Jabba"]}'




######################################################################
########################### Extra Commands ###########################
######################################################################

######################## Fetch Channel Block #########################
# # Fetch the genesis block
# peer channel fetch oldest spicechannel.block -c spicechannel $ORDERER_CONN_ARGS

######################### Chaincode Examples #########################
# # Re-install the chaincodes on the restarted peer - it should automatically be instantiated on that peer when accessed
# # First list the chaincodes instantiated on the network to know which versions to use
# peer chaincode list -C spicechannel --instantiated
# peer chaincode install -n ccWallet -v 1.0 -p chaincode/wallet
# peer chaincode install -n ccUser -v 1.0 -p chaincode/user

# # When needed, upgrade the chaincode (iterate the version)
# # Other channels bound to the old version of the chaincode still run with the old version. (https://hyperledger-fabric.readthedocs.io/en/release-1.2/chaincode4noah.html)
# peer chaincode install -n ccWallet -p chaincode/wallet -v 1.1
# peer chaincode upgrade -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.1
# peer chaincode upgrade -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.1

# # Some example commands - NOTE: If you create a user (on ccUser chaincode) via the CLI, it will not automatically create a wallet, and vice-versa
# peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["create","Han"]}'
# peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["deposit","Han", "10000"]}'
# peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","Han"]}'
# peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["transfer","Han","Jabba","12000"]}' # Han owes Jabba an extra 20% in interest