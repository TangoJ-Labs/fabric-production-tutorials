#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

# Create the needed msp directory
mkdir -p $FABRIC_CA_SERVER_HOME/msp
# Copy the prepared Fabric CA config file(s) to the home directory
cp $FABRIC_CA_SERVER_HOME/setup/fabric-ca-server-config.yaml $FABRIC_CA_SERVER_HOME
# Move the MSP config file to the MSP directory
cp /shared/config.yaml $FABRIC_CA_SERVER_HOME/msp/config.yaml

# Remove the generic cert/key that might already exist (otherwise a new ca-cert will not be created with "init")
rm $FABRIC_CA_SERVER_HOME/ca-cert.pem
rm -R $FABRIC_CA_SERVER_HOME/msp

# Initialize the CA server - this will create the "fabric-ca-server-config.yaml" file
fabric-ca-server init #-b cloudcityinc-admin-ca:adminpw

# Copy the created certificate key to the home directory (the certificate was created with "init")
# This is just for convenience and is not mandatory
cp $FABRIC_CA_SERVER_HOME/msp/keystore/*_sk $FABRIC_CA_SERVER_HOME/cloudcityinc-ca-cert.key

# Copy the root CA's signing certificate to the shared directory to be used by others
# cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/cloudcityinc-root-ca-cert.pem #v1809
cp $FABRIC_CA_SERVER_HOME/cloudcityinc-ca-cert.pem /shared/cloudcityinc-root-ca-cert.pem

# # Add the org affiliation
# sed -i "/affiliations:/a \\   cloudcityinc: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml #v1809

# Start the CA Server
fabric-ca-server start