#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "********************* LOG IN ADMIN ********************"
# If the admincerts folder already exists, the admin is already signed in
# IF YOU ENROLL AGAIN THE CERT WILL CHANGE - COULD CAUSE CHANNEL UPDATE ISSUES

export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/huttcorp/users/huttcorp-admin #MSP CORRECTION

# Always use the common dir for the Root CA Cert File (needed to be transferred anyway)
export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/huttcorp-root-ca-cert.pem

if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
    echo "Enrolling admin 'huttcorp-admin' with huttcorp-ca ..."

    fabric-ca-client enroll -d -u https://huttcorp-admin:adminpw@huttcorp-ca:7054

    ########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
    # For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin@huttcorp-cert.pem #MSP CORRECTION
    # For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin@huttcorpMSP-cert.pem #MSP CORRECTION


    ##NOTE: Do not run the admincert scripts with ". /" - this will run them asynchronously? and cause
    ## the second call to use the same optargs as the first call

    # Copy the admin cert to the admincerts dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CA_CLIENT_HOME/msp

    # Copy the admin cert to the msp dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CFG_PATH/orgs/huttcorp/msp

    # Copy the public admin cert to the common dir for distribution
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin@huttcorp-cert.pem /shared/huttcorp-admin@huttcorp-cert.pem #MSP CORRECTION
fi

export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
echo "ENROLLED AS: huttcorp-admin"
