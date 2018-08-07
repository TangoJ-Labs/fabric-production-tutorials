#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "ORDERER START"

# log a message
function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}

MSPDIR=/data/orgs/org1/msp

# Enroll for profile to get orderer's TLS cert (using the "tls" profile)
fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-orderer:ordererpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-orderer

# Copy the TLS key and cert to the tls dir
/data/tls_add_crtkey.sh -d -p /tmp/tls -c $ORDERER_GENERAL_TLS_CERTIFICATE -k $ORDERER_GENERAL_TLS_PRIVATEKEY

# cp /tmp/tls/signcerts/* /data/tls/org1-orderer.crt
# rm -rf /tmp/tls


# Enroll to get the orderer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u https://org1-orderer:ordererpw@org1-ca:7054 -M $ORDERER_GENERAL_LOCALMSPDIR

# Copy the tlscacert to the orderer msp tree
/data/msp_add_tlscacert.sh -c $ORDERER_GENERAL_LOCALMSPDIR/cacerts/* -m $ORDERER_GENERAL_LOCALMSPDIR

# Copy the admincert to the orderer msp tree
/data/msp_add_admincert.sh -c $MSPDIR/admincerts/cert.pem -m $ORDERER_GENERAL_LOCALMSPDIR


##NOTE: The genesis block should already have been created (CLI) BEFORE starting the Orderer

# Start the orderer
log "Starting orderer 'org1-orderer' with MSP at '$ORDERER_GENERAL_LOCALMSPDIR'"
orderer