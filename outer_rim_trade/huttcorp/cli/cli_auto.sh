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

export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/huttcorp-root-ca-cert.pem

mkdir -p $FABRIC_CFG_PATH/orgs/huttcorp/ca/huttcorp-admin-ca
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/huttcorp/ca/huttcorp-admin-ca

# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
fabric-ca-client enroll -d -u https://huttcorp-admin-ca:adminpw@huttcorp-ca:7054

# fabric-ca-client enroll -d --enrollment.profile tls -u https://huttcorp-admin-ca:adminpw@huttcorp-ca:7054 -M /tmp/tls/huttcorp-admin-ca

# Creates inside FABRIC_CA_CLIENT_HOME:
#...orgs/huttcorp/ca/huttcorp-admin-ca
#├── fabric-ca-client-config.yaml
#└── msp
#    ├── cacerts
#    │   └── huttcorp-ca-7054.pem
#    ├── keystore
#    │   └── {...}_sk
#    ├── signcerts
#    │   └── cert.pem
#    └── user

########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
# For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin-ca@huttcorp-cert.pem #MSP CORRECTION
# For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin-ca@huttcorpMSP-cert.pem #MSP CORRECTION


#######################################################################
############################## REGISTRATION ###########################
echo "************************* REGISTRATION ************************"

echo "Registering admin identity with huttcorp-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name huttcorp-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name huttcorp-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert"

echo "Registering huttcorp-orderer with huttcorp-ca"
fabric-ca-client register -d --id.name huttcorp-orderer --id.secret ordererpw --id.type orderer

echo "Registering huttcorp-peer0 with huttcorp-ca"
fabric-ca-client register -d --id.name huttcorp-peer0 --id.secret peerpw --id.type peer

# Generate client TLS cert and key pair for the peer commands
fabric-ca-client enroll -d --enrollment.profile tls -u https://huttcorp-peer0:peerpw@huttcorp-ca:7054 -M /tmp/tls --csr.hosts huttcorp-peer0
# Copy the TLS key and cert to the common tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/huttcorp/tls/huttcorp-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/huttcorp/tls/huttcorp-peer0-cli-client.key

#######################################################################
################################## MSP ################################
echo "***************************** MSP *****************************"

# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization)
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://huttcorp-ca:7054 -M $FABRIC_CFG_PATH/orgs/huttcorp/msp

# Creates inside MSP target:
#...orgs/huttcorp
#└── msp
#    ├── cacerts
#    │   └── huttcorp-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the huttcorp msp tree
/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/huttcorp/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/huttcorp/msp

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
################################ SDK PREP #############################

echo "Registering huttcorp-sdk default user with huttcorp-ca"
fabric-ca-client register -d --id.name huttcorp-sdk --id.secret sdkpw
. $FABRIC_CFG_PATH/setup/login.sh -u huttcorp-sdk -p sdkpw -c /shared/huttcorp-root-ca-cert.pem


#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired
# WHEN ENROLLING, BE SURE TO SET "FABRIC_CA_CLIENT_HOME" to the directory where the user msp should be created. e.g.:
# export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/huttcorp/users/huttcorp-admin
# The provided "login.sh" script will set the proper environment variables before enrollment

# fabric-ca-client register -d --id.name huttcorp-bFortuna --id.secret userpw
# . $FABRIC_CFG_PATH/setup/login.sh -u huttcorp-bFortuna -p userpw -c /shared/huttcorp-root-ca-cert.pem

# Prep for SDK
yes | go get -u github.com/hyperledger/fabric-sdk-go
yes | go get -u github.com/gin-contrib/sessions
yes | go get -u github.com/gin-contrib/static
yes | go get -u github.com/gin-gonic/gin
yes | go get -u github.com/cloudflare/cfssl/cmd/cfssl
yes | go get -u github.com/golang/mock/gomock
yes | go get -u github.com/mitchellh/mapstructure
yes | go get -u github.com/pkg/errors
yes | go get -u github.com/spf13/cast
yes | go get -u github.com/spf13/viper
yes | go get -u github.com/stretchr/testify/assert
yes | go get -u golang.org/x/crypto/ocsp
yes | go get -u golang.org/x/crypto/sha3
yes | go get -u golang.org/x/net/context
yes | go get -u google.golang.org/grpc
yes | go get -u gopkg.in/go-playground/validator.v8
yes | go get -u gopkg.in/yaml.v2

yes | apt-get update
yes | apt-get install iputils-ping