#!/bin/bash
#
# Copyright TangoJ Labs, LLC
#
# Apache-2.0
#

##### ADD AN ADMINCERT TO THE MSP TREE #####

function printHelp() {
    echo "Usage: "
    echo "  msp_add_admincert.sh <opt> <optarg>"
    echo "      options:"
    echo "          -c: PATH of cert to copy (e.g. /shared/ca-cert.pem)"
    echo "          -m: MSP directory destination (e.g. /shared/msp)"
    echo "NOTE: the admincert is always renamed 'cert.pem'"
}

# Reset the optargs
OPTIND=1

CERT=""
MSPDIR=""
while getopts ":c:m:" opt; do
    case "$opt" in
        c ) CERT=$OPTARG
            ;;
        m ) MSPDIR=$OPTARG
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

if [ "$CERT" = "" ] || [ "$MSPDIR" = "" ]; then
    printHelp
    exit 1
else
    # Create the admincerts directory
    if [ ! -d $MSPDIR/admincerts ]; then
        mkdir -p $MSPDIR/admincerts
    fi

    #Copy in the admincert
    cp $CERT $MSPDIR/admincerts/cert.pem
    cp $CERT $MSPDIR/admincerts/huttcorp-admin@huttcorp-cert.pem #MSP CORRECTION
    cp $CERT $MSPDIR/admincerts/huttcorp-admin@huttcorpMSP-cert.pem #MSP CORRECTION
fi

# Reset the optargs
OPTIND=1