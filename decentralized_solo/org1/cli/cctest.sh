#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

RUN_LOGFILE=/data/logs/run.log
RUN_SUMFILE=/data/logs/run.sum
RUN_SUCCESS_FILE=/data/logs/run.success
RUN_FAIL_FILE=/data/logs/run.fail

QUERY_TIMEOUT=15

done=false
function finish {
   if [ "$done" = true ]; then
      logr "See $RUN_LOGFILE for more details"
      touch /$RUN_SUCCESS_FILE
   else
      logr "Tests did not complete successfully; see $RUN_LOGFILE for more details"
      touch /$RUN_FAIL_FILE
      exit 1
   fi
}
function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}
function logr {
   log $*
   log $* >> $RUN_SUMFILE
}
function fatalr {
   logr "FATAL: $*"
   exit 1
}

function chaincodeQuery {
   if [ $# -ne 1 ]; then
      fatalr "Usage: chaincodeQuery <expected-value>"
   fi
   set +e
   logr "Querying chaincode in the channel 'mychannel' on the peer 'org1-peer0' ..."
   local rc=1
   local starttime=$(date +%s)
   # Continue to poll until we get a successful response or reach QUERY_TIMEOUT
   while test "$(($(date +%s)-starttime))" -lt "$QUERY_TIMEOUT"; do
      sleep 1
      peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}' >& log.txt
      VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
      if [ $? -eq 0 -a "$VALUE" = "$1" ]; then
         logr "Query of channel 'mychannel' on peer 'org1-peer0' was successful"
         set -e
         return 0
      else
         # removed the string "Query Result" from peer chaincode query command result, as a result, have to support both options until the change is merged.
         VALUE=$(cat log.txt | egrep '^[0-9]+$')
         if [ $? -eq 0 -a "$VALUE" = "$1" ]; then
            logr "Query of channel 'mychannel' on peer 'org1-peer0' was successful"
            set -e
            return 0
         fi
      fi
      echo -n "."
   done
   cat log.txt
   cat log.txt >> $RUN_SUMFILE
   fatalr "Failed to query channel 'mychannel' on peer 'org1-peer0'; expected value was $1 and found $VALUE"
}




# Wait for setup, orderer and peers to complete setup
trap finish EXIT
logr "The docker 'run' container has started"

log "************************* initOrdererVars ***********************"
export FABRIC_CA_CLIENT=/etc/hyperledger/orderer
export ORDERER_GENERAL_LOGLEVEL=DEBUG
export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
export ORDERER_GENERAL_GENESISMETHOD=file
export ORDERER_GENERAL_GENESISFILE=/data/genesis.block
export ORDERER_GENERAL_LOCALMSPID=org1MSP
export ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/orderer/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=/etc/hyperledger/orderer/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=/etc/hyperledger/orderer/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[/data/org1-ca-cert.pem]

# export ORDERER_PORT_ARGS="-o org1-orderer:7050 --tls --cafile /data/org1-ca-cert.pem --clientauth"

log "************************** initPeerVars *************************"
export FABRIC_CA_CLIENT=/opt/gopath/src/github.com/hyperledger/fabric/peer
export CORE_PEER_ID=org1-peer0
export CORE_PEER_ADDRESS=org1-peer0:7051
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
# export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=decentralized_solo
export CORE_LOGGING_LEVEL=DEBUG
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/data/org1-ca-cert.pem
export CORE_PEER_TLS_CLIENTCERT_FILE=/data/tls/org1-peer0-cli-client.crt
export CORE_PEER_TLS_CLIENTKEY_FILE=/data/tls/org1-peer0-cli-client.key
export CORE_PEER_PROFILE_ENABLED=true
export CORE_PEER_GOSSIP_USELEADERELECTION=true
export CORE_PEER_GOSSIP_ORGLEADER=false
export CORE_PEER_GOSSIP_EXTERNALENDPOINT=org1-peer0:7051

export ORDERER_CONN_ARGS="-o org1-orderer:7050 --tls --cafile /data/org1-ca-cert.pem --clientauth --keyfile /data/tls/org1-peer0-client.key --certfile /data/tls/org1-peer0-client.crt"

log "********************* switchToAdminIdentity ********************"
# If the admincerts folder already exists, the admin is already signed in
if [ ! -d /data/orgs/org1/admin ]; then
  log "Enrolling admin 'org1-admin' with org1-ca ..."
  export FABRIC_CA_CLIENT_HOME=/data/orgs/org1/admin
  export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-ca-cert.pem

  fabric-ca-client enroll -d -u https://org1-admin:adminpw@org1-ca:7054
  # Copy the cert to the admin certs dir and to the local MSP
  mkdir -p $(dirname "/data/orgs/org1/msp/admincerts/cert.pem")
  cp /data/orgs/org1/admin/msp/signcerts/* /data/orgs/org1/msp/admincerts/cert.pem
  mkdir /data/orgs/org1/admin/msp/admincerts
  cp /data/orgs/org1/admin/msp/signcerts/* /data/orgs/org1/admin/msp/admincerts
fi
export CORE_PEER_MSPCONFIGPATH=/data/orgs/org1/admin/msp


# Create the channel
log "********************** peer channel create *********************"
logr "Creating channel 'mychannel' on org1-orderer ..."
peer channel create --logging-level=DEBUG -c mychannel -f /data/channel.tx $ORDERER_CONN_ARGS


# Peers join the channel
log "*********************** peer channel join **********************"
set +e
PEERJOINCOUNT=1
MAX_RETRY=10
while true; do
    logr "Peer org1-peer0 is attempting to join channel 'mychannel' (attempt #${PEERJOINCOUNT}) ..."
    # The block to send with the join command is the block created from "peer channel create"
    peer channel join -b mychannel.block
    if [ $? -eq 0 ]; then
      set -e
      logr "Peer org1-peer0 successfully joined channel 'mychannel'"
      break
    fi
    if [ $PEERJOINCOUNT -gt $MAX_RETRY ]; then
      fatalr "Peer org1-peer0 failed to join channel 'mychannel' in $MAX_RETRY retries"
    fi
    PEERJOINCOUNT=$((PEERJOINCOUNT+1))
    sleep 1
done


# Update the anchor peers (FOR ANCHOR PEERS ONLY)
log "********************** peer channel update *********************"
logr "Updating anchor peers for org1-peer0 ..."
peer channel update -c mychannel -f /data/orgs/org1/anchors.tx $ORDERER_CONN_ARGS

# Install chaincode on peer
log "******************** peer chaincode install ********************"
logr "Installing chaincode on org1-peer0 ..."
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go

# Instantiate chaincode on peer with chaincode installed
log "****************** peer chaincode instantiate ******************"
logr "Instantiating chaincode on org1-peer0 with Policy: OR('org1MSP.member')..."
peer chaincode instantiate -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR('org1MSP.member')" $ORDERER_CONN_ARGS

# Query chaincode
log "********************* peer chaincode query *********************"
chaincodeQuery 100

# Invoke chaincode on the 1st peer of the 1st org
log "******************** peer chaincode inkoke *********************"
logr "Sending invoke transaction to org1-peer0 ..."
peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS

logr "Congratulations! The tests ran successfully."
done=true
