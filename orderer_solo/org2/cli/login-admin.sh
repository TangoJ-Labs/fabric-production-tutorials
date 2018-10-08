#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "********************* LOG IN ADMIN ********************"
# If the admincerts folder already exists, the admin is already signed in
# IF YOU ENROLL AGAIN THE CERT WILL CHANGE - COULD CAUSE CHANNEL UPDATE ISSUES

# ENROLLING USER: Create directory, set Client Home to directory, copy config file into directory (see below after directory check)
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org2/users/org2-admin #MSP CORRECTION

# Always use the common dir for the Root CA Cert File (needed to be transferred anyway)
export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org2-root-ca-cert.pem

if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
    echo "Enrolling admin 'org2-admin' with org2-ca ..."

    mkdir -p $FABRIC_CA_CLIENT_HOME/msp
    cp /shared/fabric-ca-client-config.yaml $FABRIC_CA_CLIENT_HOME
    cp /shared/config.yaml $FABRIC_CA_CLIENT_HOME/msp/config.yaml

    fabric-ca-client enroll -d -u https://org2-admin:adminpw@org2-ca:7054

    ########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
    # For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/org2-admin@org2-cert.pem #MSP CORRECTION
    # For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/org2-admin@org2MSP-cert.pem #MSP CORRECTION


    ##NOTE: Do not run the admincert scripts with ". /" - this will run them asynchronously? and cause
    ## the second call to use the same optargs as the first call
    # Copy the admin cert to the admincerts dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CA_CLIENT_HOME/msp
    # Copy the admin cert to the msp dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CFG_PATH/orgs/org2/msp

    # Copy the public admin cert to the common dir for distribution
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/org2-admin@org2-cert.pem /shared/org2-admin@org2-cert.pem #MSP CORRECTION
fi

export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
echo "ENROLLED AS: org2-admin"
