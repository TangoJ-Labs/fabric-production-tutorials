#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

echo "ORDERER START"

# Before enrolling, the client config file needs to be added to the MSP parent directory
cp /shared/fabric-ca-client-config.yaml $FABRIC_CA_CLIENT_HOME

# Enroll to get the orderer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u https://org1-orderer:ordererpw@org1-ca:7054 -M $ORDERER_GENERAL_LOCALMSPDIR
# Copy the tlscacert to the orderer msp tree
/shared/utils/msp_add_tlscacert.sh -c $ORDERER_GENERAL_LOCALMSPDIR/cacerts/* -m $ORDERER_GENERAL_LOCALMSPDIR
# Copy the admincert to the orderer msp tree
/shared/utils/msp_add_admincert.sh -c /shared/org1-admin@org1-cert.pem -m $ORDERER_GENERAL_LOCALMSPDIR #MSP CORRECTION

# Move the MSP config file to the MSP directory
cp /shared/config.yaml $ORDERER_GENERAL_LOCALMSPDIR/config.yaml

# Enroll for profile to get orderer's TLS cert (using the "tls" profile)
fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-orderer:ordererpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-orderer
# Copy the TLS key and cert to the tls dir
/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $ORDERER_GENERAL_TLS_CERTIFICATE -k $ORDERER_GENERAL_TLS_PRIVATEKEY


##NOTE: The genesis block should already have been created (CLI) BEFORE starting the Orderer

# Start the orderer
echo "Starting orderer 'org1-orderer' with MSP at '$ORDERER_GENERAL_LOCALMSPDIR'"
orderer