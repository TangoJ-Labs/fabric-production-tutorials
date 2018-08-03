#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### CREATE MSP TREE #####

# Copy the ca-cert into the tlscacerts folder (for both root ca and intermediate ca, if needed)
mkdir -p /etc/hyperledger/fabric/msp/tlscacerts
cp /etc/hyperledger/fabric/msp/cacerts/* /etc/hyperledger/fabric/msp/tlscacerts
if [ -d /etc/hyperledger/fabric/msp/intermediatecerts ]; then
    mkdir /etc/hyperledger/fabric/msp/tlsintermediatecerts
    cp /etc/hyperledger/fabric/msp/intermediatecerts/* /etc/hyperledger/fabric/msp/tlsintermediatecerts
fi

# Copy the tls data to the common folder
mkdir -p /data/orgs/org1/msp/cacerts
mkdir -p /data/orgs/org1/msp/tlscacerts
cp /etc/hyperledger/fabric/msp/cacerts/* /data/orgs/org1/msp/cacerts
cp /etc/hyperledger/fabric/msp/cacerts/* /data/orgs/org1/msp/tlscacerts
if [ -d /data/orgs/org1/msp/intermediatecerts ]; then
    mkdir /data/orgs/org1/msp/tlsintermediatecerts
    cp /etc/hyperledger/fabric/msp/intermediatecerts/* /data/orgs/org1/msp/intermediatecerts
    cp /etc/hyperledger/fabric/msp/intermediatecerts/* /data/orgs/org1/msp/tlsintermediatecerts
fi

# Copy admincert to MSP and to my local MSP
# mkdir -p $(dirname "/data/orgs/org1/msp/admincerts/cert.pem")
mkdir /data/orgs/org1/msp/admincerts
cp /etc/hyperledger/fabric/msp/signcerts/* /data/orgs/org1/msp/admincerts

# Create the admin MSP by first copying over the existing home dir MSP, then modify
mkdir -p /data/orgs/org1/admin/msp
cp -R /etc/hyperledger/fabric/msp /data/orgs/org1/admin
mkdir /data/orgs/org1/admin/msp/admincerts
cp /etc/hyperledger/fabric/msp/signcerts/* /data/orgs/org1/admin/msp/admincerts