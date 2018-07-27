#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### COPY PEER CERTS #####

# Copy the TLS key and cert to the local tls dir
if [ ! -d /data/tls ]; then
    mkdir -p /data/tls
fi
cp /tmp/tls/signcerts/* /data/tls/org1-peer0-client.crt
cp /tmp/tls/keystore/* /data/tls/org1-peer0-client.key
rm -rf /tmp/tls

# Finish setting up the local MSP for the orderer
mkdir /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/tlscacerts
cp /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/cacerts/* /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/tlscacerts

if [ -d /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/intermediatecerts ]; then
    mkdir /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/tlsintermediatecerts
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/intermediatecerts/* /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/tlsintermediatecerts
fi

mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/admincerts
cp /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/signcerts/* /opt/gopath/src/github.com/hyperledger/fabric/peer/msp/admincerts