#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "ORDERER START"

# # Move the configuration file to the home dir
# cp $FABRIC_CA_CLIENT_HOME/setup/fabric-ca-client-config.yaml $FABRIC_CA_CLIENT_HOME


set -e

# log a message
function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}

# Wait for setup to complete sucessfully

# Enroll to get orderer's TLS cert (using the "tls" profile)
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-orderer:ordererpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-orderer

# Copy the TLS key and cert to the appropriate place
mkdir -p $FABRIC_CA_CLIENT_HOME/tls
cp /tmp/tls/keystore/* $ORDERER_GENERAL_TLS_PRIVATEKEY
cp /tmp/tls/signcerts/* $ORDERER_GENERAL_TLS_CERTIFICATE
# Copy the public cert to the org common directory
cp /tmp/tls/signcerts/* /data/tls/org2-orderer.crt
rm -rf /tmp/tls

# Enroll again to get the orderer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u https://org2-orderer:ordererpw@org2-ca:7054 -M $ORDERER_GENERAL_LOCALMSPDIR

# Finish setting up the local MSP for the orderer
# finishMSPSetup $ORDERER_GENERAL_LOCALMSPDIR
mkdir $ORDERER_GENERAL_LOCALMSPDIR/tlscacerts
cp $ORDERER_GENERAL_LOCALMSPDIR/cacerts/* $ORDERER_GENERAL_LOCALMSPDIR/tlscacerts
if [ -d $ORDERER_GENERAL_LOCALMSPDIR/intermediatecerts ]; then
    mkdir $ORDERER_GENERAL_LOCALMSPDIR/tlsintermediatecerts
    cp $ORDERER_GENERAL_LOCALMSPDIR/intermediatecerts/* $ORDERER_GENERAL_LOCALMSPDIR/tlsintermediatecerts
fi

# copyAdminCert $ORDERER_GENERAL_LOCALMSPDIR
mkdir -p $ORDERER_GENERAL_LOCALMSPDIR/admincerts
cp /data/orgs/org2/msp/admincerts/cert.pem $ORDERER_GENERAL_LOCALMSPDIR/admincerts

# Wait for the genesis block to be created

# Start the orderer
log "Starting orderer 'org2-orderer' with MSP at '$ORDERER_GENERAL_LOCALMSPDIR'"
env | grep ORDERER
orderer