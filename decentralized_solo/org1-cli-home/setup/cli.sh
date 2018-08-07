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


#######################################################################
################################ CA ADMIN #############################
log "************************* enrollCAAdmin *************************"
log "Enrolling with org1-ca as bootstrap identity ..."

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-root-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org1/ca
if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
  mkdir -p $FABRIC_CA_CLIENT_HOME
fi
# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054




#------------------------------------------------------------------------------------


# log "************************ initOrdererVars ************************"
# # export FABRIC_CA_CLIENT=/etc/hyperledger/orderer

# log "Registering org1-orderer with org1-ca"
# fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer

# log "Registering admin identity with org1-ca"
# # The admin identity has the "admin" attribute which is added to ECert by default
# # fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "admin=true:ecert"
# fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"


# log "********************* registerPeerIdentities ********************"
# log "************************** initPeerVars *************************"
# # export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

# log "Registering org1-peer0 with org1-ca"
# fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer

# log "Registering user identity with org1-ca"
# fabric-ca-client register -d --id.name org1-user1 --id.secret userpw


# log "************************** getCACerts **************************"
# log "Getting CA certs for organization org1 and storing in /data/orgs/org1/msp"

# fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /data/orgs/org1/msp

# log "************************ finishMSPSetup ************************"
# if [ ! -d /data/orgs/org1/msp/tlscacerts ]; then
#   mkdir /data/orgs/org1/msp/tlscacerts
#   cp /data/orgs/org1/msp/cacerts/* /data/orgs/org1/msp/tlscacerts
#   if [ -d /data/orgs/org1/msp/intermediatecerts ]; then
#       mkdir /data/orgs/org1/msp/tlsintermediatecerts
#       cp /data/orgs/org1/msp/intermediatecerts/* /data/orgs/org1/msp/tlsintermediatecerts
#   fi
# fi

# # Enroll the ORG ADMIN and populate the admincerts directory
# source /etc/hyperledger/fabric/setup/switchToAdmin.sh


#------------------------------------------------------------------------------------

# Copy the tlscacert to the admin-ca msp tree
# . /data/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org1/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org1/msp

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
#    └── user                 <--- Here we will add the MSP trees for the admins / users we enroll on the CLI

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
# cp -R $FABRIC_CFG_PATH/msp /data/orgs/org1/admin/msp

# Set needed env vars
# export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

log "Getting CA certs for organization org1 and storing in /data/orgs/org1/msp"
# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://org1-ca:7054 -M $FABRIC_CFG_PATH/orgs/org1

# Creates inside FABRIC_CFG_PATH/orgs/org1:
#.
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the admin-ca msp tree
. /data/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org1/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org1/msp


# Enroll the ORG ADMIN and populate the admincerts directory
$FABRIC_CFG_PATH/setup/login-admin.sh

log "************************ finishMSPSetup ************************"
# source $FABRIC_CFG_PATH/setup/generate_msp.sh

# The login-admin script will enroll the admin and receive a crypto material
# The admin's public cert will be copied to the common directory - copy this
# admincert to the msp tree main branch
. /data/msp_add_admincert.sh -c /data/org1-admin-cert.pem -m $FABRIC_CFG_PATH/orgs/org1/msp

#######################################################################
########################### CHANNEL ARTIFACTS #########################

log "******************* generateChannelArtifacts ********************"
$FABRIC_CFG_PATH/setup/generate_channel_artifacts.sh


# Move the genesis block to the common folder (for orderer start w/ ORDERER_GENERAL_GENESISFILE)
cp $FABRIC_CFG_PATH/genesis.block /data

#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired

# fabric-ca-client register -d --id.name org1-user1 --id.secret userpw
# fabric-ca-client enroll -d -u https://org1-user1:userpw@org1-ca:7054
