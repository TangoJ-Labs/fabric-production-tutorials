# Quickstart Instructions

If you're still learning about Hyperledger Fabric, please try the manual process at least once - it's a great way to "feel" around the network components and understand how they interact.  Watch the output and skim the log files for even more detail.

<br>

NOTES:
- IMPORTANT: CHANGE THE `docker-compose.yaml` files to use the `*_auto.sh` scripts for each container, otherwise the containers will not automatically setup when started.
- Be sure to check for errors in the logs (in the `/shared` directories) after each container startup.

<br>

# SETUP - DOCKER NETWORK
Start the network separately to ensure the network name is consistent in all secondary docker-compose files.
<br>
<br>**0.1) Start the Docker Network**
>`docker network create orderer_solo`

(you can check the running docker networks with `docker network list`)

<br>Move to this network's top directory:
>`cd {repo home}/orderer_solo`

<br>
<br>

# ORG 1 SETUP
**1.1) org1 CA start**
<br>Setup the org1 CA and register the CA ADMIN
>`docker-compose -f org1/ca/docker-compose.yaml up -d`

<br>

**1.2) org1 CLI start**
<br>Setup the org1 CLI and register users and nodes
>`docker-compose -f org1/cli/docker-compose.yaml up -d`

<br>

**1.3) org1 orderer start**
>`docker-compose -f org1/orderer/docker-compose.yaml up -d`

<br>

**1.4) org1 peer0 start**
>`docker-compose -f org1/peer0/docker-compose.yaml up -d`

<br>

**1.5) org1 chaincode start**

Setup the org1 chaincode and test from inside the org1 CLI
>`docker exec -it org1-cli bash`

#### The following step occurs inside the org1 CLI Bash session:
>Update the channel and upgrade the chaincode:
>>`. /etc/hyperledger/fabric/setup/cctest.sh`
>
>If successful, in the terminal you should see:
>>`Congratulations! The tests ran successfully.`
>
>End the Bash session with `exit`

<br>
<br>

# ORG 2 SETUP, CHANNEL JOIN, & UPGRADE CHAINCODE
**2.1) org2 CA start**
<br>Setup the org2 CA and register the CA ADMIN
>`docker-compose -f org2/ca/docker-compose.yaml up -d`

<br>

**2.2) org2 CLI start**
>`docker-compose -f org2/cli/docker-compose.yaml up -d`

The org2 CLI startup script should have created the needed artifacts (MSP tree):
-  Enrolled the CA ADMIN
-  Registered the ORG ADMIN & PEER
-  Got CA CERT and completed MSP tree
-  Generated org info .json with configtxgen (and copied to shared dir)

<br>

**2.3) MANUAL TRANSFER org2 -> org1**
- Copy created `.json` file to org1 `/shared` directory

**2.4) MANUAL TRANSFER org1 -> org2**
- Copy `org1-root-ca-cert.pem` to org2 `/shared` directory

<br>

**2.5) org2 peer0 start**
>`docker-compose -f org2/peer0/docker-compose.yaml up -d`

<br>

**2.6) org1 CLI**
>`docker exec -it org1-cli bash`

#### The following step occurs inside the org1 CLI Bash session:
>Update the channel and upgrade the chaincode:
>>`. /etc/hyperledger/fabric/setup/add_org/add_org_upgrade_cc.sh`
>
>The terminal should show a change in the targeted value (e.g. 4990 vs. the original 5000)
>
>End the Bash session with `exit`

<br>

**2.7) org2 CLI**
>`docker exec -it org2-cli bash`

#### The following step occurs inside the org2 CLI Bash session:
>Join the channel and install the chaincode:
>>`. /etc/hyperledger/fabric/setup/add_org/add_org_install_cc.sh`
>
>The terminal should show a change in the targeted value (e.g. 4980 vs. the last 4990)
>
>End the Bash session with `exit`

<br>
<br>

## FINISHED
That's it!  Both orgs are on the network, channel, and using the same chaincode.  Be on the lookout for updates to this repo - an SDK example (golang) will be added soon.

<br>

### OPTIONAL:

WARNING: THE FOLLOWING COMMANDS WILL REMOVE ALL DOCKER CONTAINERS ON YOUR MACHINE (not just Hyperledger services) - USE WITH CAUTION

You can shut down the network with:
>`{repo home}/network_down.sh`

Or, for automatic cleaning of script-created files, try:
>`yes | {repo home}/network_down.sh delete`