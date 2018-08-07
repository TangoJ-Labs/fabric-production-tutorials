#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0
#

##### ADD AN ADMINCERT TO THE MSP TREE #####

function printHelp() {
    echo "Usage: "
    echo "  msp_add_tlscacert.sh <opt> <optarg>"
    echo "      options:"
    echo "          -c: PATH of cert to copy (e.g. /data/ca-cert.pem)"
    echo "          -m: MSP directory destination (e.g. /data/msp)"
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
    # Create the tlscacert directory
    if [ ! -d $MSPDIR/tlscacerts ]; then
        mkdir -p $MSPDIR/tlscacerts
    fi
    #Copy in the tlscacert
    cp $CERT $MSPDIR/tlscacerts

    # Create the tlsintermediatecerts directory, if needed
    if [ -d $MSPDIR/intermediatecerts ]; then
        if [ ! -d $MSPDIR/tlsintermediatecerts ]; then
            mkdir -p $MSPDIR/tlsintermediatecerts
        fi
        #Copy in the tlsintermediatecerts
        cp $MSPDIR/intermediatecerts/* $MSPDIR/tlsintermediatecerts
    fi
fi

# Reset the optargs
OPTIND=1
