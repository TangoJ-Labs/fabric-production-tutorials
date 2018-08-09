#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "********************* LOG IN ADMIN ********************"
# If the admincerts folder already exists, the admin is already signed in
# IF YOU ENROLL AGAIN THE CERT WILL CHANGE - COULD CAUSE CHANNEL UPDATE ISSUES

export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org1/msp/user/org1-admin

# Always use the common dir for the Root CA Cert File (needed to be transferred anyway)
export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org1-root-ca-cert.pem

if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
    echo "Enrolling admin 'org1-admin' with org1-ca ..."

    fabric-ca-client enroll -d -u https://org1-admin:adminpw@org1-ca:7054


    ##NOTE: Do not run the admincert scripts with ". /" - this will run them asynchronously? and cause
    ## the second call to use the same optargs as the first call

    # Copy the admin cert to the admincerts dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CA_CLIENT_HOME/msp

    # Copy the admin cert to the msp dir
    /shared/utils/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CFG_PATH/orgs/org1/msp

    # Copy the public admin cert to the common dir for distribution
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem /shared/org1-admin-cert.pem
fi

export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
echo "ENROLLED AS: org1-admin"
