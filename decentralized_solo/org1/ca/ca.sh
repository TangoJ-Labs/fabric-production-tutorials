#!/bin/bash

# Because we are providing a config file, we do not need to run initilization
# fabric-ca-server init -b org1-admin-ca:adminpw

# Move the configuration file to the home dir
cp $FABRIC_CA_SERVER_HOME/setup/fabric-ca-server-config.yaml $FABRIC_CA_SERVER_HOME

# Start the CA Server
fabric-ca-server start