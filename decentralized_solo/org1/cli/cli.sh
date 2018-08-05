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

# # Affiliation is not used to limit users in this sample, so just put
# # all identities in the same affiliation.
# export FABRIC_CA_CLIENT_ID_AFFILIATION=org1


#######################################################################
################################ CA ADMIN #############################
log "************************* enrollCAAdmin *************************"
log "Enrolling with org1-ca as bootstrap identity ..."

if [ ! -d $FABRIC_CFG_PATH/orgs/org1/ca ]; then
  mkdir -p $FABRIC_CFG_PATH/orgs/org1/ca
fi
# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-root-ca-cert.pem

fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054

# Creates inside FABRIC_CA_CLIENT_HOME:
#.
#├── fabric-ca-client-config.yaml
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    │   └── {...}_sk
#    ├── signcerts
#    │   └── cert.pem
#    └── user

# log "************************ initOrdererVars ************************"
# export FABRIC_CA_CLIENT=/etc/hyperledger/orderer


#######################################################################
############################## REGISTRATION ###########################

log "Registering org1-orderer with org1-ca"
fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer

log "Registering admin identity with org1-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"

log "********************* registerPeerIdentities ********************"
# log "************************** initPeerVars *************************"
# export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

log "Registering org1-peer0 with org1-ca"
fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer


#######################################################################
################################## MSP ################################
cp -R /etc/hyperledger/fabric/msp /data/orgs/org1/admin/msp

# Set needed env vars
# export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

log "Getting CA certs for organization org1 and storing in /data/orgs/org1/msp"
# # -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /data/orgs/org1/msp
fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /etc/hyperledger/fabric/msp

# Creates inside FABRIC_CFG_PATH:
#.
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Enroll the ORG ADMIN and populate the admincerts directory
source /etc/hyperledger/fabric/setup/login-admin.sh

log "************************ finishMSPSetup ************************"
# OPTIONAL: MSP TREE
source /etc/hyperledger/fabric/setup/generate_msp.sh



#######################################################################
########################### CHANNEL ARTIFACTS #########################

log "******************* generateChannelArtifacts ********************"
source /etc/hyperledger/fabric/setup/generate_channel_artifacts.sh




#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired

# fabric-ca-client register -d --id.name org1-user1 --id.secret userpw
# fabric-ca-client enroll -d -u https://org1-user1:userpw@org1-ca:7054