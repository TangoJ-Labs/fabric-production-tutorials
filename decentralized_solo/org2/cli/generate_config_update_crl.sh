#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Start the configtxlator
configtxlator start &
configtxlator_pid=$!
log "configtxlator_pid:$configtxlator_pid"
logr "Sleeping 5 seconds for configtxlator to start..."
sleep 5

pushd /tmp

CTLURL=http://127.0.0.1:7059
# Convert the config block protobuf to JSON
curl -X POST --data-binary /tmp/config_block.pb $CTLURL/protolator/decode/common.Block > config_block.json
# Extract the config from the config block
jq .data.data[0].payload.data.config config_block.json > config.json

# Update crl in the config json
cat config.json | jq --arg org "org1" --arg crl "$(cat /data/orgs/org1/msp/crls/crl*.pem | base64 | tr -d '\n')" '.channel_group.groups.Application.groups[$org].values.MSP.value.config.revocation_list = [$crl]' > updated_config.json

# Create the config diff protobuf
curl -X POST --data-binary @config.json $CTLURL/protolator/encode/common.Config > config.pb
curl -X POST --data-binary @updated_config.json $CTLURL/protolator/encode/common.Config > updated_config.pb
curl -X POST -F original=@config.pb -F updated=@updated_config.pb $CTLURL/configtxlator/compute/update-from-configs -F channel=dsolo > config_update.pb

# Convert the config diff protobuf to JSON
curl -X POST --data-binary @config_update.pb $CTLURL/protolator/decode/common.ConfigUpdate > config_update.json

# Create envelope protobuf container config diff to be used in the "peer channel update" command to update the channel configuration block
echo '{"payload":{"header":{"channel_header":{"channel_id":"dsolo", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' > config_update_as_envelope.json
curl -X POST --data-binary @config_update_as_envelope.json $CTLURL/protolator/encode/common.Envelope > /tmp/config_update_as_envelope.pb

# Stop configtxlator
kill $configtxlator_pid

popd