#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### CREATE MSP TREE #####

# Copy the ca-cert into the tlscacerts folder (for both root ca and intermediate ca, if needed)
mkdir /data/orgs/org1/msp/tlscacerts
cp /data/orgs/org1/msp/cacerts/* /data/orgs/org1/msp/tlscacerts

if [ -d /data/orgs/org1/msp/intermediatecerts ]; then
    mkdir /data/orgs/org1/msp/tlsintermediatecerts
    cp /data/orgs/org1/msp/intermediatecerts/* /data/orgs/org1/msp/tlsintermediatecerts
fi

# Copy admincert to MSP and to my local MSP
mkdir -p $(dirname "/data/orgs/org1/msp/admincerts/cert.pem")
cp /etc/hyperledger/cli/msp/signcerts/* /data/orgs/org1/msp/admincerts/cert.pem

# Create the admin MSP by first copying over the existing home dir MSP, then modify
mkdir -p /data/orgs/org1/admin/msp
cp -R /etc/hyperledger/cli/msp /data/orgs/org1/admin
mkdir /data/orgs/org1/admin/msp/admincerts
cp /etc/hyperledger/cli/msp/signcerts/* /data/orgs/org1/admin/msp/admincerts