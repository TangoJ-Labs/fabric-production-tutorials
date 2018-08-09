#!/bin/bash
#
# Copyright Viskous Corporation
#
# Apache-2.0
#

##### ADD TLS CRT & KEY #####

function printHelp() {
    echo "Usage: "
    echo "  tls_add_crtkey.sh <opt> <optarg>"
    echo "      options:"
    echo "          -p: PATH the current tls directory"
    echo "          -c: filepath + filename of where to save CRT"
    echo "          -k: filepath + filename of where to save KEY"
    echo "          -d: DELETE the current tls directory after copying"
}

# Reset the optargs
OPTIND=1

TLSDIR=""
CRT=""
KEY=""
DELETE=false
while getopts ":p:c:k:d" opt; do
    case "$opt" in
        p ) TLSDIR=$OPTARG
            ;;
        c ) CRT=$OPTARG
            ;;
        k ) KEY=$OPTARG
            ;;
        d ) DELETE=true
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

if [ $TLSDIR = "" ] || [ $CRT = "" ] || [ $KEY = "" ]; then
    printHelp
    exit 1
else
    # Create the destination directories if needed and copy
    if [ ! -d $(dirname $CRT) ]; then
        mkdir -p $(dirname $CRT)
    fi
    cp $TLSDIR/signcerts/cert.pem $CRT

    if [ ! -d $(dirname $KEY) ]; then
        mkdir -p $(dirname $KEY)
    fi
    cp $TLSDIR/keystore/*_sk $KEY
    
    if $DELETE; then
        rm -rf $TLSDIR
    fi
fi

# Reset the optargs
OPTIND=1
