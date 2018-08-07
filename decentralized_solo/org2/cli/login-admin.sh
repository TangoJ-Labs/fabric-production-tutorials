#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "********************* LOG IN ADMIN ********************"
# If the admincerts folder already exists, the admin is already signed in
# IF YOU ENROLL AGAIN THE CERT WILL CHANGE - COULD CAUSE CHANNEL UPDATE ISSUES

# MSPDIR=$FABRIC_CFG_PATH/orgs/org2/msp
MSPDIR=/data/orgs/org2/msp

# export FABRIC_CA_CLIENT_HOME=$MSPDIR/user/org2-admin
export FABRIC_CA_CLIENT_HOME=$MSPDIR/user/admin

# Always use the common dir for the Root CA Cert File (needed to be transferred anyway)
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org2-root-ca-cert.pem

if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
    echo "Enrolling admin 'org2-admin' with org2-ca ..."

    fabric-ca-client enroll -d -u https://org2-admin:adminpw@org2-ca:7054


    ##NOTE: Do not run the admincert scripts with ". /" - this will run them asynchronously? and cause
    ## the second call to use the same optargs as the first call

    # Copy the admin cert to the admincerts dir
    /data/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $FABRIC_CA_CLIENT_HOME/msp

    # Copy the admin cert to the msp dir
    /data/msp_add_admincert.sh -c $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem -m $MSPDIR


    #----------------------------------------------------------------

    # # Copy the admin cert to the admin dir
    # mkdir -p $FABRIC_CA_CLIENT_HOME/msp/admincerts
    # cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/admincerts/cert.pem

    # # Copy the admin cert to the msp dir
    # mkdir -p $MSPDIR/admincerts
    # cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $MSPDIR/admincerts/cert.pem

    #----------------------------------------------------------------

    # # Copy the tlscacert to the admin-ca msp tree
    # /data/msp_add_tlscacert.sh -c $FABRIC_CA_CLIENT_HOME/msp/cacerts/* -m $FABRIC_CA_CLIENT_HOME/msp

    # Copy the public admin cert to the common dir for distribution
    cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem /data/org2-admin-cert.pem
    

    # # Copy the admin config file - ACTUALLY DON'T - MISSING OTHER SETTINGS & GETTING "OrganizationalUnit" error relating to MSP / CSR setup
    # # CANNOT USE ".peer", ".client" ENDORSEMENT POLICY ON CHAINCODE UNTIL THIS IS FIXED (can use ".member")
    # cp /etc/hyperledger/fabric/msp/config.yaml /data/orgs/org2/admin/msp/config.yaml

    # MANUALLY copy back the config file AFTER editing
    # cp /data/orgs/org2/admin/msp/config.yaml /etc/hyperledger/fabric/msp/config.yaml
fi

export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
echo "ENROLLED AS: org2-admin"
