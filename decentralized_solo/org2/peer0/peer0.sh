#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


echo "PEER START"

# # Move the configuration file to the home dir
# cp $FABRIC_CA_CLIENT_HOME/setup/fabric-ca-client-config.yaml $FABRIC_CA_CLIENT_HOME


# set -e

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

# Although a peer may use the same TLS key and certificate file for both inbound and outbound TLS,
# we generate a different key and certificate for inbound and outbound TLS simply to show that it is permissible

# Generate server TLS cert and key pair for the peer
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert locally
mkdir -p $FABRIC_CA_CLIENT_HOME/tls
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_KEY_FILE
rm -rf /tmp/tls


# Generate client TLS cert and key pair for the peer
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the common directory
mkdir /data/tls || true
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CLIENTCERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_CLIENTKEY_FILE
rm -rf /tmp/tls


# Generate client TLS cert and key pair for the peer CLI
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the common directory
mkdir /data/tls || true
cp /tmp/tls/signcerts/* /data/tls/org2-peer0-cli-client.crt
cp /tmp/tls/keystore/* /data/tls/org2-peer0-cli-client.key
rm -rf /tmp/tls


# Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
fabric-ca-client enroll -d -u https://org2-peer0:peerpw@org2-ca:7054 -M $CORE_PEER_MSPCONFIGPATH

# finishMSPSetup $CORE_PEER_MSPCONFIGPATH
mkdir $CORE_PEER_MSPCONFIGPATH/tlscacerts
cp $CORE_PEER_MSPCONFIGPATH/cacerts/* $CORE_PEER_MSPCONFIGPATH/tlscacerts
if [ -d $CORE_PEER_MSPCONFIGPATH/intermediatecerts ]; then
    mkdir $CORE_PEER_MSPCONFIGPATH/tlsintermediatecerts
    cp $CORE_PEER_MSPCONFIGPATH/intermediatecerts/* $CORE_PEER_MSPCONFIGPATH/tlsintermediatecerts
fi

# copyAdminCert $CORE_PEER_MSPCONFIGPATH
mkdir -p $CORE_PEER_MSPCONFIGPATH/admincerts
cp /data/orgs/org2/msp/admincerts/cert.pem $CORE_PEER_MSPCONFIGPATH/admincerts

# Start the peer
log "Starting peer 'org2-peer0' with MSP at '$CORE_PEER_MSPCONFIGPATH'"
env | grep CORE
peer node start