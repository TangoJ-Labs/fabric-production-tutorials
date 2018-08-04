#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### CREATE MSP TREE #####

# Copy the ca-cert into the tlscacerts dir (for both root ca and intermediate ca, if needed)
if [ ! -d /etc/hyperledger/fabric/msp/tlscacerts ]; then
    mkdir -p /etc/hyperledger/fabric/msp/tlscacerts
fi
cp /etc/hyperledger/fabric/msp/cacerts/* /etc/hyperledger/fabric/msp/tlscacerts
if [ -d /etc/hyperledger/fabric/msp/intermediatecerts ]; then
    mkdir -p /etc/hyperledger/fabric/msp/tlsintermediatecerts
    cp /etc/hyperledger/fabric/msp/intermediatecerts/* /etc/hyperledger/fabric/msp/tlsintermediatecerts
fi

# Copy the cacerts folder from local to common directory
if [ ! -d /data/orgs/org1/msp/cacerts ]; then
    mkdir -p /data/orgs/org1/msp/cacerts
fi
cp /etc/hyperledger/fabric/msp/cacerts/* /data/orgs/org1/msp/cacerts

# Copy the tlscacerts folder from local to common directory
if [ ! -d /data/orgs/org1/msp/tlscacerts ]; then
    mkdir -p /data/orgs/org1/msp/tlscacerts
fi
cp /data/orgs/org1/msp/cacerts/* /data/orgs/org1/msp/tlscacerts

# If needed, copy the intermediatecerts & tlsintermediatecerts folder from local to common directory
if [ -d /etc/hyperledger/fabric/msp/intermediatecerts ]; then
    if [ ! -d /data/orgs/org1/msp/intermediatecerts ]; then
        mkdir -p /data/orgs/org1/msp/intermediatecerts
        cp /data/orgs/org1/msp/intermediatecerts/* /data/orgs/org1/msp/intermediatecerts
    fi
    if [ ! -d /data/orgs/org1/msp/tlsintermediatecerts ]; then
        mkdir -p /data/orgs/org1/msp/tlsintermediatecerts
        cp /data/orgs/org1/msp/intermediatecerts/* /data/orgs/org1/msp/tlsintermediatecerts
    fi
fi


# Copy the admincerts folder from local to common directory
if [ ! -d /data/orgs/org1/msp/admincerts ]; then
    mkdir -p /data/orgs/org1/msp/admincerts
fi
cp /etc/hyperledger/fabric/msp/signcerts/cert.pem /data/orgs/org1/msp/admincerts/cert.pem
