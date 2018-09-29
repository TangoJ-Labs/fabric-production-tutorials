#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

# Initialize the CA server - this will create the "fabric-ca-server-config.yaml" file
fabric-ca-server init -b huttcorp-admin-ca:adminpw

# Copy the root CA's signing certificate to the shared directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/huttcorp-root-ca-cert.pem

# Add the org affiliation
sed -i "/affiliations:/a \\   huttcorp: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the CA Server
fabric-ca-server start