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
export FABRIC_CA_CLIENT_ID_AFFILIATION=org2

log "********************** registerIdentities ***********************"
log "******************* registerOrdererIdentities *******************"
log "************************* enrollCAAdmin *************************"
log "Enrolling with org2-ca as bootstrap identity ..."
export FABRIC_CA_CLIENT_HOME=$HOME/cas/org2-ca
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org2-ca-cert.pem

fabric-ca-client enroll -d -u https://org2-admin-ca:adminpw@org2-ca:7054

 
log "********************* registerPeerIdentities ********************"
log "************************** initPeerVars *************************"
export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer

log "Registering admin identity with org2-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
 
log "Registering org2-peer0 with org2-ca"
fabric-ca-client register -d --id.name org2-peer0 --id.secret peerpw --id.type peer

log "Registering user identity with org2-ca"
fabric-ca-client register -d --id.name org2-user1 --id.secret userpw


log "************************** getCACerts **************************"
log "Getting CA certs for organization org2 and storing in /data/orgs/org2/msp"

fabric-ca-client getcacert -d -u https://org2-ca:7054 -M /data/orgs/org2/msp

log "************************ finishMSPSetup ************************"
if [ ! -d /data/orgs/org2/msp/tlscacerts ]; then
  mkdir /data/orgs/org2/msp/tlscacerts
  cp /data/orgs/org2/msp/cacerts/* /data/orgs/org2/msp/tlscacerts
  if [ -d /data/orgs/org2/msp/intermediatecerts ]; then
      mkdir /data/orgs/org2/msp/tlsintermediatecerts
      cp /data/orgs/org2/msp/intermediatecerts/* /data/orgs/org2/msp/tlsintermediatecerts
  fi
fi

# Enroll the ORG ADMIN and populate the admincerts directory
source /etc/hyperledger/fabric/setup/switchToAdmin.sh


touch /data/logs/setup2.successful