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

export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org1-root-ca-cert.pem

mkdir -p $FABRIC_CFG_PATH/orgs/org1/ca/org1-admin-ca
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org1/ca/org1-admin-ca

# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054

# Creates inside FABRIC_CA_CLIENT_HOME:
#...orgs/org1/ca/org1-admin-ca
#├── fabric-ca-client-config.yaml
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    │   └── {...}_sk
#    ├── signcerts
#    │   └── cert.pem
#    └── user

########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
# For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/org1-admin-ca@org1-cert.pem #MSP CORRECTION
# For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/org1-admin-ca@org1MSP-cert.pem #MSP CORRECTION


#######################################################################
############################## REGISTRATION ###########################
echo "************************* REGISTRATION ************************"

echo "Registering admin identity with org1-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"

echo "Registering org1-orderer with org1-ca"
fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer

echo "Registering org1-peer0 with org1-ca"
fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer

# Generate client TLS cert and key pair for the peer commands
fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-peer0:peerpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-peer0
# Copy the TLS key and cert to the common tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/org1/tls/org1-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/org1/tls/org1-peer0-cli-client.key

#######################################################################
################################## MSP ################################
echo "***************************** MSP *****************************"

# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization)
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://org1-ca:7054 -M $FABRIC_CFG_PATH/orgs/org1/msp

# Creates inside MSP target:
#...orgs/org1
#└── msp
#    ├── cacerts
#    │   └── org1-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the org1 msp tree
/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org1/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org1/msp

# Enroll the ORG ADMIN and populate the admincerts directory
##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars
. $FABRIC_CFG_PATH/setup/login-admin.sh


#######################################################################
########################### CHANNEL ARTIFACTS #########################

echo "****************** generateChannelArtifacts *******************"
$FABRIC_CFG_PATH/setup/generate_channel_artifacts.sh

# Move the genesis block to the shared directory
##NOTE: Needed for orderer start w/ ORDERER_GENERAL_GENESISFILE
cp $FABRIC_CFG_PATH/genesis.block /shared



#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired

# fabric-ca-client register -d --id.name org1-user1 --id.secret userpw
# fabric-ca-client enroll -d -u https://org1-user1:userpw@org1-ca:7054
