#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "PEER START"


# Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
fabric-ca-client enroll -d -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M $CORE_PEER_MSPCONFIGPATH
# Copy the tlscacert to the orderer msp tree
/shared/utils/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH
# Copy the admincert to the admin-ca msp tree
/shared/utils/msp_add_admincert.sh -c /shared/cloudcityinc-admin@cloudcityinc-cert.pem -m $CORE_PEER_MSPCONFIGPATH #MSP CORRECTION


# Generate server TLS cert and key pair for the peer commands (if executed from peer container)
fabric-ca-client enroll -d --enrollment.profile tls -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M /tmp/tls --csr.hosts cloudcityinc-peer0
# Copy the TLS key and cert to the local tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE


# Start the peer
echo "Starting peer 'cloudcityinc-peer0' with MSP at '$CORE_PEER_MSPCONFIGPATH'"
peer node start
