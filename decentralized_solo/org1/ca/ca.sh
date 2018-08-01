#!/bin/bash

# Because we are providing a config file, we do not need to run initilization
fabric-ca-server init -b org1-admin-ca:adminpw #>/data/logs/ca.log 2>&1

# Copy the root CA's signing certificate to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /data/org1-ca-cert.pem

# Add the org affiliation
sed -i "/affiliations:/a \\   org1: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the CA Server
fabric-ca-server start #>/data/logs/ca.log 2>&1