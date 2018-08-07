which configtxgen
if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
fi

###### NOTE: The channelID (for both system and application) have some
# type of unknown restriction - best to keep them all lowercase and <12 characters

# Ensure the logged-in user has admin capabilities to access needed MSP settings:
### FABRIC_CFG_PATH (where the configtx.yaml file resides)
### CORE_PEER_LOCALMSPID
### CORE_PEER_MSPCONFIGPATH

export FABRIC_CFG_PATH=/etc/hyperledger/fabric
export CORE_PEER_LOCALMSPID=org1MSP


# Copy the configtx.yaml file into the home directory
cp $FABRIC_CFG_PATH/setup/configtx.yaml $FABRIC_CFG_PATH/configtx.yaml

which configtxgen
if [ "$?" -ne 0 ]; then
  fatal "configtxgen tool not found. exiting"
fi

echo "Generating orderer genesis block at /data/genesis.block"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
configtxgen -profile OrgsOrdererGenesis -outputBlock $FABRIC_CFG_PATH/genesis.block
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate orderer genesis block"
fi

echo "Generating channel configuration transaction at /data/channel.tx"
configtxgen -profile OrgsChannel -outputCreateChannelTx $FABRIC_CFG_PATH/channel.tx \
            -channelID mychannel
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate channel configuration transaction"
fi

echo "Generating anchor peer update transaction for org1 at /data/orgs/org1/anchors.tx"
configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $FABRIC_CFG_PATH/org1-anchors.tx \
            -channelID mychannel -asOrg org1
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate anchor peer update for org1"
fi

echo "Finished building channel artifacts"