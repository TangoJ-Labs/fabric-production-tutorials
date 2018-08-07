#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# RUN IN org1 CLI

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"

echo "========= Creating config transaction to add org3 to network =========== "
echo "Installing jq"
apt-get -y update && apt-get -y install jq

# Fetch the config for the channel, writing it to config.json
echo "========= fetchChannelConfig =========== "
#setOrdererGlobals
source ../.env

echo "Fetching the most recent configuration block for the channel"
peer channel fetch config config_block.pb -c mychannel $ORDERER_CONN_ARGS

echo "Decoding config block to JSON and isolating config to config.json"
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json


echo "========= MODIFY CONFIG =========== "
# Modify the configuration to append org2
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"org2":.[1]}}}}}' config.json org2.json > modified_config.json


echo "========= createConfigUpdate =========== "
# Compute a config update, based on the differences between config.json and
# modified_config.json, write it as a transaction to org3_update_in_envelope.pb
configtxlator proto_encode --input config.json --type common.Config >original_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config >modified_config.pb
configtxlator compute_update --channel_id mychannel --original original_config.pb --updated modified_config.pb >config_update.pb
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"update_in_envelope.pb"
  

echo "========= signConfigtxAsPeerOrg ===== "
echo "Signing config transaction"
# setGlobals
peer channel signconfigtx -f update_in_envelope.pb


echo "========= Submit transaction from a different peer if needed ========= "
# Copy the envelope to the common directory and pass to needed other authorizing admins
# (if only one org currently, this signature should be enough)
cp update_in_envelope.pb /data/update_in_envelope.pb
echo "========= Config transaction to add org2 sent to common directory =========== "

exit 0
