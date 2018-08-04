#!/bin/bash
#
# Copyright Viskous Corporation. All Rights Reserved.
#
# Apache-2.0
#

function printHelp() {
  echo "Usage: "
  echo "  generate_tls_for_host.sh <enrollment address> <targeted host>"
  echo "    <enrollment address> should be in the format username:password@ca-address:port"
}

# Commandline arguments:
#    1) username:password@ca-address:port
#    2) Targeted host
ADDRESS=$1 #org2-admin:adminpw@org2-ca:7054
HOST=$2 #org1-peer0

fabric-ca-client enroll -d --enrollment.profile tls -u https://$ADDRESS -M /tmp/tls --csr.hosts $HOST

# Copy the TLS key and cert to the common directory
if [ ! -d /data/tls ]; then
    mkdir /data/tls
fi
cp /tmp/tls/tlscacerts/* /data/tls/$HOST-tlsrootcert.pem
cp /tmp/tls/signcerts/* /data/tls/$HOST-tls-client.crt
cp /tmp/tls/keystore/* /data/tls/$HOST-tls-client.key
rm -rf /tmp/tls

echo "TLS CERT REQUEST COMPLETE"