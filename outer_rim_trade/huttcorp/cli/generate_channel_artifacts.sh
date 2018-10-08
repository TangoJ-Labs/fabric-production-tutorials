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
export CORE_PEER_LOCALMSPID=huttcorpMSP

# Copy the configtx.yaml file into the home directory
cp $FABRIC_CFG_PATH/setup/configtx.yaml $FABRIC_CFG_PATH/configtx.yaml

which configtxgen
if [ "$?" -ne 0 ]; then
  echo "configtxgen tool not found. exiting"
  exit 1
fi

echo "Generating orderer genesis block at $FABRIC_CFG_PATH/genesis.block"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
# To understand the difference between the orderer (system) channel and the application channel
# naming, see this thread: https://lists.hyperledger.org/g/fabric/topic/17549890
configtxgen -profile OrgsOrdererGenesis -outputBlock $FABRIC_CFG_PATH/genesis.block \
            -channelID spicechannelorderers
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block"
  exit 1
fi

echo "Generating channel configuration transaction at $FABRIC_CFG_PATH/channel.tx"
configtxgen -profile OrgsChannel -outputCreateChannelTx $FABRIC_CFG_PATH/channel.tx \
            -channelID spicechannel
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction"
  exit 1
fi

echo "Generating anchor peer update transaction for huttcorp at $FABRIC_CFG_PATH/huttcorp-anchors.tx"
configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $FABRIC_CFG_PATH/huttcorp-anchors.tx \
            -channelID spicechannel -asOrg huttcorp
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for huttcorp"
  exit 1
fi

echo "Finished building channel artifacts"