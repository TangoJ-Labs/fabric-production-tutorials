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
log "************************ ENROLL CA ADMIN ************************"

export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-root-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/data/orgs/org1/ca #$FABRIC_CFG_PATH/orgs/org1/ca
if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
  mkdir -p $FABRIC_CA_CLIENT_HOME
fi
# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
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


#######################################################################
############################## REGISTRATION ###########################
log "************************** REGISTRATION *************************"

MSPDIR=$FABRIC_CFG_PATH
MSPDIR=/data

log "Registering org1-orderer with org1-ca"
fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer

log "Registering admin identity with org1-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"

log "Registering org1-peer0 with org1-ca"
fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer


#######################################################################
################################## MSP ################################
log "***************************** MSP *******************************"

# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://org1-ca:7054 -M $MSPDIR/orgs/org1/msp

# Creates inside MSP target:
#.
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the admin-ca msp tree
/data/msp_add_tlscacert.sh -c $MSPDIR/orgs/org1/msp/cacerts/* -m $MSPDIR/orgs/org1/msp

# Enroll the ORG ADMIN and populate the admincerts directory
##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars
. $FABRIC_CFG_PATH/setup/login-admin.sh


#######################################################################
########################### CHANNEL ARTIFACTS #########################

log "******************* generateChannelArtifacts ********************"
$FABRIC_CFG_PATH/setup/generate_channel_artifacts.sh

# Move the genesis block to the common folder (for orderer start w/ ORDERER_GENERAL_GENESISFILE)
##NOTE: Needed for org2 join - send to org2 common dir
cp $FABRIC_CFG_PATH/genesis.block /data




#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired

# fabric-ca-client register -d --id.name org1-user1 --id.secret userpw
# fabric-ca-client enroll -d -u https://org1-user1:userpw@org1-ca:7054
