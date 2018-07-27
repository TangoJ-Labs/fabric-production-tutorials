#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### COPY ORDERER CERTS #####

# Copy the TLS key and cert to the common tls dir
if [ ! -d /data/tls ]; then
    mkdir -p /data/tls
fi
cp /tmp/tls/keystore/* /data/tls/server.key
cp /tmp/tls/signcerts/* /data/tls/server.crt
rm -rf /tmp/tls

# Finish setting up the local MSP for the orderer
mkdir /etc/hyperledger/orderer/msp/tlscacerts
cp /etc/hyperledger/orderer/msp/cacerts/* /etc/hyperledger/orderer/msp/tlscacerts

if [ -d /etc/hyperledger/orderer/msp/intermediatecerts ]; then
    mkdir /etc/hyperledger/orderer/msp/tlsintermediatecerts
    cp /etc/hyperledger/orderer/msp/intermediatecerts/* /etc/hyperledger/orderer/msp/tlsintermediatecerts
fi

mkdir -p /etc/hyperledger/orderer/msp/admincerts
cp /etc/hyperledger/orderer/msp/signcerts/* /etc/hyperledger/orderer/msp/admincerts