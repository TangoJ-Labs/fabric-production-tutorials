which configtxgen
if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
fi

###### NOTE: The channelID (for both system and application) have some
# type of unknown restriction - best to keep them all lowercase and <12 characters

export FABRIC_CFG_PATH=/etc/hyperledger/fabric/setup
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_PEER_MSPCONFIGPATH=/data/orgs/org1/admin/msp
# export ORDERER_GENERAL_LOCALMSPID=org1MSP
# export ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/orderer/msp


echo "Generating orderer genesis block to /data"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
configtxgen -outputBlock /data/genesis.block -profile OrgOrdererGenesis \
            -channelID dsolosystem #--configPath /etc/hyperledger/fabric/setup/configtx.yaml
if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block"
    exit 1
fi

echo "Generating channel configuration transaction to /data"
configtxgen -outputCreateChannelTx /data/channel.tx -profile OrgChannel \
            -channelID dsolo #-configPath /etc/hyperledger/fabric/setup/configtx.yaml
if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction"
    exit 1
fi

echo "Generating anchor peer update transaction for org1 to /data"
configtxgen -outputAnchorPeersUpdate /data/orgs/org1/anchors.tx -profile OrgChannel \
            -channelID dsolo -asOrg org1 #--configPath /etc/hyperledger/fabric/setup/configtx.yaml
if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for org1"
    exit 1
fi