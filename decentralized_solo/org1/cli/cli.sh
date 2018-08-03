#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#
# This script does the following:
# 1) registers orderer and peer identities with fabric-ca-server
# 2) Builds the channel artifacts (e.g. genesis block, etc)
#

# Move the configuration file to the home dir
# cp $FABRIC_CA_CLIENT_HOME/setup/{fabric-ca-client-config.yaml,configtx.yaml} $FABRIC_CA_CLIENT_HOME
# cp $FABRIC_CFG_PATH/setup/configtx.yaml $FABRIC_CFG_PATH

#BEGIN: setup-fabric.sh
# set -e

function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}
function fatal {
   log "FATAL: $*"
   exit 1
}

# Affiliation is not used to limit users in this sample, so just put
# all identities in the same affiliation.
export FABRIC_CA_CLIENT_ID_AFFILIATION=org1

log "********************** registerIdentities ***********************"
log "******************* registerOrdererIdentities *******************"
log "************************* enrollCAAdmin *************************"
log "Enrolling with org1-ca as bootstrap identity ..."
export FABRIC_CA_CLIENT_HOME=$HOME/cas/org1-ca
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-ca-cert.pem

fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054

log "************************ initOrdererVars ************************"
export FABRIC_CA_CLIENT=/etc/hyperledger/orderer

log "Registering org1-orderer with org1-ca"
fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer

log "Registering admin identity with org1-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"



# fabric-ca-client register -d --id.name org1-user5 --id.secret userpw --id.type peer

# # -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# fabric-ca-client register -d --id.name peercheck --id.secret password --id.type peer
# fabric-ca-client enroll -d -u https://peercheck:password@org1-ca:7054




log "********************* registerPeerIdentities ********************"
log "************************** initPeerVars *************************"
export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

log "Registering org1-peer0 with org1-ca"
fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer

log "Registering user identity with org1-ca"
fabric-ca-client register -d --id.name org1-user1 --id.secret userpw


log "************************** getCACerts **************************"
log "Getting CA certs for organization org1 and storing in /data/orgs/org1/msp"

fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /data/orgs/org1/msp

log "************************ finishMSPSetup ************************"
if [ ! -d /data/orgs/org1/msp/tlscacerts ]; then
  mkdir /data/orgs/org1/msp/tlscacerts
  cp /data/orgs/org1/msp/cacerts/* /data/orgs/org1/msp/tlscacerts
  if [ -d /data/orgs/org1/msp/intermediatecerts ]; then
      mkdir /data/orgs/org1/msp/tlsintermediatecerts
      cp /data/orgs/org1/msp/intermediatecerts/* /data/orgs/org1/msp/tlsintermediatecerts
  fi
fi

# Enroll the ORG ADMIN and populate the admincerts directory
source /etc/hyperledger/fabric/setup/switchToAdmin.sh


log "******************* generateChannelArtifacts ********************"
# Copy the configtx.yaml file into the home directory
cp $FABRIC_CFG_PATH/setup/configtx.yaml $FABRIC_CFG_PATH/configtx.yaml

which configtxgen
if [ "$?" -ne 0 ]; then
  fatal "configtxgen tool not found. exiting"
fi

log "Generating orderer genesis block at /data/genesis.block"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
configtxgen -profile OrgsOrdererGenesis -outputBlock /data/genesis.block
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate orderer genesis block"
fi

log "Generating channel configuration transaction at /data/channel.tx"
configtxgen -profile OrgsChannel -outputCreateChannelTx /data/channel.tx \
            -channelID mychannel
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate channel configuration transaction"
fi

log "Generating anchor peer update transaction for org1 at /data/orgs/org1/anchors.tx"
configtxgen -profile OrgsChannel -outputAnchorPeersUpdate /data/orgs/org1/anchors.tx \
            -channelID mychannel -asOrg org1
if [ "$?" -ne 0 ]; then
  fatal "Failed to generate anchor peer update for org1"
fi

log "Finished building channel artifacts"
touch /data/logs/setup.successful


# fabric-ca-client enroll -d -u https://org1-user1:userpw@org1-ca:7054