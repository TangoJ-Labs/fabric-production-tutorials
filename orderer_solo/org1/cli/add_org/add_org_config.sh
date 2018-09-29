#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# RUN IN org1 CLI

# Specify the chaincode package location:
# CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"


#######################################################################
############################### INSTALL jq ############################
apt-get -y update && apt-get -y install jq


#######################################################################
############################## CONFIG FETCH ###########################
#Set the environment variables
source /etc/hyperledger/fabric/setup/.env

# Fetch the most recent configuration block for the channel
# and write it to config.json
peer channel fetch config config_block.pb -c mychannel $ORDERER_CONN_ARGS

# Decode config block to JSON and isolate config to config.json
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json


#######################################################################
############################# CONFIG MODIFY ###########################
# Modify the configuration to append org2
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"org2":.[1]}}}}}' config.json /shared/org2.json > modified_config.json


#######################################################################
######################### CREATE CONFIG UPDATE ########################
# Compute a config update, based on the differences between config.json and
# modified_config.json, write it as a transaction to update_in_envelope.pb
configtxlator proto_encode --input config.json --type common.Config >original_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config >modified_config.pb
configtxlator compute_update --channel_id mychannel --original original_config.pb --updated modified_config.pb >config_update.pb
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json

# CAUTION: The following "echo" is NOT an output note - it is needed for the jq process
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"update_in_envelope.pb"
  

#######################################################################
############################## SIGN CONFIG ############################
peer channel signconfigtx -f update_in_envelope.pb

# Copy the envelope to the common directory and pass to other authorizing admins (if needed)
# (if only one org currently, this signature should be enough)
cp update_in_envelope.pb /shared/update_in_envelope.pb
