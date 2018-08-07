#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "PEER START"

# log a message
function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}

MSPDIR=/data/orgs/org2/msp

# Although a peer may use the same TLS key and certificate file for both inbound and outbound TLS,
# we generate a different key and certificate for inbound and outbound TLS simply to show that it is permissible

# Generate server TLS cert and key pair for the peer
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the local tls dir
. /data/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE


# Generate client TLS cert and key pair for the peer
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the common tls dir
. /data/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CLIENTCERT_FILE -k $CORE_PEER_TLS_CLIENTKEY_FILE


# Generate client TLS cert and key pair for the peer CLI
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the common tls dir
. /data/tls_add_crtkey.sh -d -p /tmp/tls -c /data/tls/org2-peer0-cli-client.crt -k /data/tls/org2-peer0-cli-client.key


# Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
fabric-ca-client enroll -d -u https://org2-peer0:peerpw@org2-ca:7054 -M $CORE_PEER_MSPCONFIGPATH

# Copy the tlscacert to the orderer msp tree
/data/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH

# Copy the admincert to the admin-ca msp tree
/data/msp_add_admincert.sh -c $MSPDIR/admincerts/cert.pem -m $CORE_PEER_MSPCONFIGPATH


# Start the peer
log "Starting peer 'org2-peer0' with MSP at '$CORE_PEER_MSPCONFIGPATH'"
peer node start
