#!/bin/bash

# Initialize the Org1 CA Server
fabric-ca-server init -b $BOOTSTRAP_USER_PASS

# Copy the crypto material to this org's data folder
# (tls-cert.pem is not made until the server is started)
mkdir data
cp -R $FABRIC_CA_SERVER_HOME/{ca-cert.pem,tls-cert.pem,IssuerPublicKey,IssuerRevocationPublicKey,msp} $FABRIC_CA_SERVER_HOME/data

# Move the configuration file to the home dir
cp $FABRIC_CA_SERVER_HOME/setup/fabric-ca-server-config.yaml $FABRIC_CA_SERVER_HOME

# Start the Org1 CA Server
fabric-ca-server start