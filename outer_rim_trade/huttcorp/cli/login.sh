#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##### LOG IN OR ENROLL A USER #####

function printHelp() {
    echo "DO NOT USE FOR ADMIN ACCOUNTS - does not set admin properties"
    echo "Usage: "
    echo "  login.sh <username:password> <opt> <optarg>"
    echo "      options:"
    echo "          -u: (required) username"
    echo "          -p: (required) password"
    echo "          -c: (required) Root CA Cert filepath"
}

# Reset the optargs
OPTIND=1

USERNAME=""
PASSWORD=""
HOME=""
CACERT=""
while getopts ":u:p:h:c:a:m" opt; do
    case "$opt" in
        u ) USERNAME=$OPTARG
            ;;
        p ) PASSWORD=$OPTARG
            ;;
        c ) CACERT=$OPTARG
            ;;
        \? )
          printHelp
          exit 1
          ;;
        : )
          printHelp
          exit 1
          ;;
    esac
done

if [ $USERNAME = "" ] || [ $PASSWORD = "" ] || [ $CACERT = "" ]; then
    printHelp
    exit 1
else
    echo "********************* LOG IN USER ********************"
    # Always use the common dir for the Root CA Cert File (needed to be transferred anyway)
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$CACERT

    export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/huttcorp/users/$USERNAME #MSP CORRECTION

    # If the user's msp folder already exists, the user has already been enrolled, so
    # just reassign the needed environment variables
    if [ ! -d $FABRIC_CA_CLIENT_HOME/msp ]; then
        echo "ENROLLING $USERNAME"

        fabric-ca-client enroll -d -u https://$USERNAME:$PASSWORD@huttcorp-ca:7054
        

        ########## Copy the signcerts file to follow all needed MSP naming rules for the SDK ##########
        # For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
        cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/$USERNAME@huttcorp-cert.pem #MSP CORRECTION
        # For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
        cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/$USERNAME@huttcorpMSP-cert.pem #MSP CORRECTION
    fi

    export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
    echo "ENROLLED AS: $USERNAME"
fi

# Reset the optargs
OPTIND=1
