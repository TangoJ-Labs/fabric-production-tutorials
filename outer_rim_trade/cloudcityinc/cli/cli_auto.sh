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

export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/cloudcityinc-root-ca-cert.pem

# ENROLLING USER: Create directory, set Client Home to directory, copy config file into directory
mkdir -p $FABRIC_CFG_PATH/orgs/cloudcityinc/ca/cloudcityinc-admin-ca/msp
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/cloudcityinc/ca/cloudcityinc-admin-ca
cp /shared/fabric-ca-client-config.yaml $FABRIC_CA_CLIENT_HOME
# Move the MSP config file to the CA Admin MSP directory
cp /shared/config.yaml $FABRIC_CA_CLIENT_HOME/msp/config.yaml

# Enroll the CA Admin using the bootstrap CA profile (used when setting up the CA service)
fabric-ca-client enroll -d -u https://cloudcityinc-admin-ca:adminpw@cloudcityinc-ca:7054

# Creates inside FABRIC_CA_CLIENT_HOME:
#.
#├── fabric-ca-client-config.yaml
#└── msp
#    ├── cacerts
#    │   └── cloudcityinc-ca-7054.pem
#    ├── keystore
#    │   └── {...}_sk
#    ├── signcerts
#    │   └── cert.pem
#    └── user

########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
# For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/cloudcityinc-admin-ca@cloudcityinc-cert.pem #MSP CORRECTION
# For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/cloudcityinc-admin-ca@cloudcityincMSP-cert.pem #MSP CORRECTION


#######################################################################
############################## REGISTRATION ###########################
echo "************************* REGISTRATION ************************"

echo "Registering admin identity with cloudcityinc-ca"
# The admin identity has the "admin" attribute which is added to ECert by default
# fabric-ca-client register -d --id.name cloudcityinc-admin --id.secret adminpw --id.attrs "admin=true:ecert"
fabric-ca-client register -d --id.name cloudcityinc-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert"

echo "Registering cloudcityinc-peer0 with cloudcityinc-ca"
fabric-ca-client register -d --id.name cloudcityinc-peer0 --id.secret peerpw --id.type peer #id type "peer" necessary when using NodeOUs and an endorsement policy requiring "peer" endorsement

# Generate client TLS cert and key pair for the peer commands
fabric-ca-client enroll -d --enrollment.profile tls -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M /tmp/tls --csr.hosts cloudcityinc-peer0
# Copy the TLS key and cert to the local tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/cloudcityinc/tls/cloudcityinc-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/cloudcityinc/tls/cloudcityinc-peer0-cli-client.key

#######################################################################
################################## MSP ################################
echo "***************************** MSP *****************************"

# -M option is WHERE TO LOOK FOR CURRENT MSP DIR (for authorization) based on home at current FABRIC_CA_CLIENT_HOME
# SAME AS THE ROOT CA CERT
fabric-ca-client getcacert -d -u https://cloudcityinc-ca:7054 -M $FABRIC_CFG_PATH/orgs/cloudcityinc/msp

# Creates inside MSP target:
#.
#└── msp
#    ├── cacerts
#    │   └── cloudcityinc-ca-7054.pem
#    ├── keystore
#    ├── signcerts
#    └── user

# Copy the tlscacert to the cloudcityinc msp tree
/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/cloudcityinc/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/cloudcityinc/msp


#######################################################################
########################### JOIN CHANNEL PREP #########################

# Move the MSP config file to the CA Admin MSP directory
cp /shared/config.yaml $FABRIC_CFG_PATH/orgs/cloudcityinc/msp/config.yaml

##NOTE: MUST RUN login-admin.sh with ". /" to capture env vars

# Set env vars & enroll the ORG ADMIN & complete ADMIN MSP tree
source /etc/hyperledger/fabric/setup/.env
. /etc/hyperledger/fabric/setup/login-admin.sh

# Move the configtx.yaml file to the FABRIC_CFG_PATH directory (see docker compose env vars)
cp /etc/hyperledger/fabric/setup/configtx.yaml /etc/hyperledger/fabric/configtx.yaml

# Generate the Org info using the configtxgen tool for joining the existing channel
configtxgen -channelID mychannel -printOrg cloudcityinc > cloudcityinc.json

# pass cloudcityinc.json to common folder for use by authorizing org(s)
cp cloudcityinc.json /shared/cloudcityinc.json


#######################################################################
################################ SDK PREP #############################

echo "Registering cloudcityinc-sdk default user with cloudcityinc-ca"
fabric-ca-client register -d --id.name cloudcityinc-sdk --id.secret sdkpw
. $FABRIC_CFG_PATH/setup/login.sh -u cloudcityinc-sdk -p sdkpw -c /shared/cloudcityinc-root-ca-cert.pem


#######################################################################
#######################################################################
################################ OPTIONAL #############################
#######################################################################
#######################################################################

# Register and enroll users, other peers, etc. if desired
# WHEN ENROLLING, BE SURE TO SET "FABRIC_CA_CLIENT_HOME" to the directory where the user msp should be created. e.g.:
# export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/cloudcityinc/users/cloudcityinc-admin
# The provided "login.sh" script will set the proper environment variables before enrollment

# fabric-ca-client register -d --id.name cloudcityinc-lobot --id.secret userpw
# . $FABRIC_CFG_PATH/setup/login.sh -u cloudcityinc-lobot -p userpw -c /shared/cloudcityinc-root-ca-cert.pem


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