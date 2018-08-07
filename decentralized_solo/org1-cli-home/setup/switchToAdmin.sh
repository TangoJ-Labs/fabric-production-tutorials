#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "********************* switchToAdminIdentity ********************"
# If the admincerts folder already exists, the admin is already signed in
# IF YOU ENROLL AGAIN THE CERT WILL CHANGE - COULD CAUSE CHANNEL UPDATE ISSUES

export FABRIC_CA_CLIENT_HOME=/data/orgs/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-root-ca-cert.pem

if [ ! -d /data/orgs/org1/admin ]; then
    echo "Enrolling admin 'org1-admin' with org1-ca ..."

    fabric-ca-client enroll -d -u https://org1-admin:adminpw@org1-ca:7054

    # Copy the admin cert to the admin dir
    mkdir -p /data/orgs/org1/admin/msp/admincerts
    cp /data/orgs/org1/admin/msp/signcerts/cert.pem /data/orgs/org1/admin/msp/admincerts/cert.pem

    # Copy the admin cert to the msp dir
    mkdir -p /data/orgs/org1/msp/admincerts
    cp /data/orgs/org1/admin/msp/signcerts/cert.pem /data/orgs/org1/msp/admincerts/cert.pem

    # # Copy the admin config file
    # cp /etc/hyperledger/fabric/msp/config.yaml /data/orgs/org2/admin/msp/config.yaml
fi

export CORE_PEER_MSPCONFIGPATH=/data/orgs/org1/admin/msp
# export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/msp
echo "ENROLLED AS: org1-admin"
