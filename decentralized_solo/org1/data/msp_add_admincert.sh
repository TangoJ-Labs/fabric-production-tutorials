#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0
#

##### ADD AN ADMINCERT TO THE MSP TREE #####

function printHelp() {
    echo "Usage: "
    echo "  msp_add_admincert.sh <opt> <optarg>"
    echo "      options:"
    echo "          -c: PATH of cert to copy (e.g. /data/ca-cert.pem)"
    echo "          -m: MSP directory destination (e.g. /data/msp)"
    echo "NOTE: the admincert is always renamed 'cert.pem'"
}

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
fi

# Reset the optargs
OPTIND=1