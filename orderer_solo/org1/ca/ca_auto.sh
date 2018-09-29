#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

# Initialize the CA server - this will create the "fabric-ca-server-config.yaml" file
fabric-ca-server init -b org1-admin-ca:adminpw #>>/shared/logs/ca.log 2>&1 &

# Copy the root CA's signing certificate to the shared directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/org1-root-ca-cert.pem

# Start the CA Server
fabric-ca-server start #>>/shared/logs/ca.log 2>&1 &