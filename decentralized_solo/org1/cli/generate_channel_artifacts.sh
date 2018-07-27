which configtxgen
if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
fi

echo "Generating orderer genesis block to /data"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
configtxgen -outputBlock /data/genesis.block -profile OrgOrdererGenesis \
            -channelID decentralized_solo_system
if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block"
    exit 1
fi

echo "Generating channel configuration transaction to /data"
configtxgen -outputCreateChannelTx /data/channel.tx -profile OrgChannel \
            -channelID decentralized_solo
if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction"
    exit 1
fi

echo "Generating anchor peer update transaction for org1 to /data"
configtxgen -outputAnchorPeersUpdate /data/anchors.tx -profile OrgChannel \
            -channelID decentralized_solo -asOrg org1
if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for org1"
    exit 1
fi