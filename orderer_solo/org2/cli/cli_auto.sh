#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#
# This script does the following:
# 1) registers orderer and peer identities with fabric-ca-server
# 2) Builds the channel artifacts (e.g. genesis block, etc)
#

#######################################################################
################################ CA ADMIN #############################
echo "*********************** ENROLL CA ADMIN ***********************"

export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org2-root-ca-cert.pem

mkdir -p $FABRIC_CFG_PATH/orgs/org2/ca/org2-admin-ca
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org2/ca/org2-admin-ca

# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
fabric-ca-client enroll -d -u https://org2-admin-ca:adminpw@org2-ca:7054

# Creates inside FABRIC_CA_CLIENT_HOME:
#.
#├── fabric-ca-client-config.yaml
#└── msp
#    ├── cacerts
#    │   └── org2-ca-7054.pem
#    ├── keystore
#    │   └── {...}_sk
#    ├── signcerts
#    │   └── cert.pem
#    └── user


#######################################################################
############################## REGISTRATION ###########################
echo "************************* REGISTRATION ************************"

echo "Registering admin identity with org2-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"

echo "Registering org2-peer0 with org2-ca"
fabric-ca-client register -d --id.name org2-peer0 --id.secret peerpw --id.type peer

# Generate client TLS cert and key pair for the peer commands
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0
# Copy the TLS key and cert to the local tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/org2/tls/org2-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/org2/tls/org2-peer0-cli-client.key

#######################################################################
################################## MSP ################################
echo "***************************** MSP *****************************"

# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://org2-ca:7054 -M $FABRIC_CFG_PATH/orgs/org2/msp

# Creates inside MSP target:
#.
#└── msp
#    ├── cacerts
#    │   └── org2-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the admin-ca msp tree
/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org2/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org2/msp


#######################################################################
########################### JOIN CHANNEL PREP #########################

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

# Set env vars & enroll the ORG ADMIN & complete ADMIN MSP tree
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# Move the configtx.yaml file to the FABRIC_CFG_PATH directory (see docker compose env vars)
cp /etc/hyperledger/fabric/setup/configtx.yaml /etc/hyperledger/fabric/configtx.yaml

# Generate the Org info using the configtxgen tool for joining the existing channel
configtxgen -channelID mychannel -printOrg org2 > org2.json

# pass org2.json to common folder for use by authorizing org(s)
cp org2.json /shared/org2.json




#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired

# fabric-ca-client register -d --id.name org2-user1 --id.secret userpw
# fabric-ca-client enroll -d -u https://org2-user1:userpw@org2-ca:7054
