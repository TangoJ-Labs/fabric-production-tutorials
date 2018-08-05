#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0

############################### OPTIONAL ##############################
#######################################################################
############################### MSP TREE ##############################
#######################################################################

# Reset the org common directory MSP tree
rm -rf /data/orgs
# Create the initial structure for the org common MSP tree
mkdir -p /data/orgs/org1/ca

# Copy the Root CA Cert and associated private key to the MSP tree
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /data/orgs/org1/ca/root-ca-cert.pem
cp $FABRIC_CA_SERVER_HOME/msp/keystore/*_sk /data/orgs/org1/ca
