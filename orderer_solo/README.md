# Solo Orderer HLF Network (simplified)
This network runs on a solo orderer (hosted by one org) and static docker containers (no swarm, etc.)

---
## NOTES
* A "decentralized" service implies equality among members, but since we are using a solo Orderer, only one Orderer node can exist, so a single (in this case the first) organization will host the Orderer.

* In this Hyperledger network setup, each org needs its own CA (Certificate Authority) to issue cryptographic materials.

* Most services (containers) also include a `*_auto.sh` file in their directory.  You can use these scripts (change the docker-compose file `command:` section) to more quickly setup the network.  The manual steps are listed below for educational purposes.  Try out the manual process to get a better feel for how the network components interact.

* Most Hyperledger Fabric examples create a complete MSP tree in a shared directory (whether using the `cryptogen` utility or multiple CAs).  In production you will not create an entire MSP tree in one location exposing all private keys to misuse.  In production you will leave the private keys in each service (container), and only share the public certs when needed.  We will follow production protocol and keep almost all crypto material in each respective container, only sharing a minimal amount of public material.

* IF YOU MODIFY THE ORG NAMES, change the commands in this tutorial as needed, and be sure to check the `docker-compose.yaml` and `configtx.yaml` files.

---

### Cryptographic Material: For an overview of the MSP structure, check out the [CRYPTO](../CRYPTO.md) page.

## QUICKSTART: For fewer manual steps, see the [QUICKSTART README](QUICKSTART.md).

<br>
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

# ORG 1
## ORG 1 CA Service
**1.1) Start the org1 CA service**
>`docker-compose -f org1/ca/docker-compose.yaml up -d`

**1.2) Start a Bash session in the org1 CA service**
>`docker exec -it org1-ca bash`

NOTE: If you explore the container filesystem, a CA cert and key are created in a `.../fabric-ca-server` sibling directory to the home directory.  This material can be ignored for our purposes.  The CSR detail on this material is default, and we will not use this crypto material for our network.
<br>
<br>

#### The following step occurs inside the org1 CA Bash session:
>**1.3) Initialize the CA server**
>>`fabric-ca-server init -b org1-admin-ca:adminpw >>/shared/logs/ca.log 2>&1 &`
>
>The `>>...` redirect will hide the stdout and stderror from your command line.  You will need to open `ca.log` to check for errors.  You can change the `admin:adminpw` parameter to whatever admin username / password you want for the CA server admin.
>
>A `fabric-ca-server-config.yaml` file, root CA certificate `ca-cert.pem`, and `.../keystore` directory with private keys will be created at the server home directory (set by `FABRIC_CA_SERVER_HOME` in the docker-compose file).  We will override many of the config file CSR settings with environmental variables (the config file will still show default settings).  The entire structure should resemble:
>
><pre style="line-height: 1.3;">
>.
>├── fabric-ca-server.db
>├── fabric-ca-server-config.yaml
>├── IssuerPublicKey
>├── IssuerRevocationPublicKey
>├── tls-cert.pem
>├── ca-cert.pem            <--- If you used Cryptogen instead, it would save this Root CA Cert to shared MSP tree
>└── msp
>    ├── cacerts
>    ├── keystore
>    │   ├── {...}_sk       <--- If you used Cryptogen instead, it would save this Root CA private key to shared MSP tree
>    │   ├── IssuerRevocationPrivateKey
>    │   └── IssuerSecretKey
>    ├── signcerts
>    └── user
></pre>
>
><br>
>
>**1.4) Copy the crypto material**
>
>Copy the Root CA Cert ONLY to the shared folder for production use.
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/org1-root-ca-cert.pem`
>
>The Root CA Cert is needed to `enroll` from the CLI.  We will refer to this file in other services (containers) via the `FABRIC_CA_CLIENT_TLS_CERTFILES` environment variable.  You could also hard-code the filename in the CLI config file (fabric-ca-client-config.yaml) in the `tls: certfiles:` section to include the cert as a trusted root certificate.
>
><br>
>
>**1.5) Edit the CA Server Config File**
>>`sed -i "/affiliations:/a \\   org1: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml`
>
>The docs do not indicate a way to set the `affiliations:` section of the config file via environment variables, so we will manually edit that section.
>
><br>
>
>**1.6) Start the CA Server**
>>`fabric-ca-server start >>/shared/logs/ca.log 2>&1 &`
>
>Again, this will redirect all output to the log file.  Check `ca.log` and ensure that the service is listening on the default port (7054).
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 1 CLI (tools) Service
**1.7) Start the org1 CLI (tools) service**
>`docker-compose -f org1/cli/docker-compose.yaml up -d`

<br>

**1.8) Start a Bash session in the org1 CLI service**
>`docker exec -it org1-cli bash`

#### The following steps occur inside the org1 CLI Bash session:
>If you exit and re-enter the Bash session, you might need to reset the environment variables.  Example: `export FABRIC_CFG_PATH=/etc/hyperledger/fabric`
>
><br>
>
>**1.9) Enroll the CA administrator**
><br>First, create the needed msp directory and set the environment variables needed.  The `$FABRIC_CFG_PATH` was set when the container was started (default: `/etc/hyperledger/fabric`)
>>`mkdir -p $FABRIC_CFG_PATH/orgs/org1/ca/org1-admin-ca`
><br>`export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org1-root-ca-cert.pem`
><br>`export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org1/ca/org1-admin-ca`
>
><br>Enroll the CA admin:
>>`fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054`
>
><br>An MSP directory should have been created in the `FABRIC_CA_CLIENT_HOME` directory (currently `$FABRIC_CFG_PATH/orgs/org1/ca/org1-admin-ca`), with a default client config file (if not preexisting).  The `msp/cacerts/org1-ca-7054.pem` is the same certificate as the ca-cert.pem (renamed org1-ca-cert.pem) we created in the CA and passed to the `/shared` directory to be used in the CLI config file.
>
><pre style="line-height: 1.3;">
>...orgs/org1/ca/org1-admin-ca
>└── msp
>    ├── cacerts
>    │   └── org1-ca-7054.pem   <--- matches Root CA Cert ("org1-ca-cert.pem")
>    ├── keystore
>    │   ├── {...}_sk
>    ├── signcerts
>    │   └── cert.pem
>    └── user
></pre>
>
><br>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**1.10) Register the org administrator**
><br>The admin identity has the "admin" attribute which is added to ECert by default.  The other attributes are needed for this example chaincode settings.  Register the admin:
>>`fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"`
>
><br>
>
>**1.11) Register the orderer profile**
>>`fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer`
>
><br>
>
>**1.12) Register the peer profile**
>>`fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer`
>
><br>
>
>**1.13) (OPTIONAL) Register a user**
>>`fabric-ca-client register -d --id.name org1-user1 --id.secret userpw`
>
><br>
>
>**1.14) Generate client TLS cert and key pair for the peer commands**
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-peer0:peerpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-peer0`
>
>Copy the TLS key and cert to the common tls dir
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/org1/tls/org1-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/org1/tls/org1-peer0-cli-client.key`
>
>
><br>
>
>**1.15) Create the MSP directory tree**
><br>Get the root ca cert again and auto-create the org1 MSP tree
>>`fabric-ca-client getcacert -d -u https://org1-ca:7054 -M $FABRIC_CFG_PATH/orgs/org1/msp`
>
><pre style="line-height: 1.3;">
>...orgs/org1
>└── msp
>    ├── cacerts
>    │   └── org1-ca-7054.pem   <--- from "fabric-ca-client getcacert"
>    ├── keystore
>    ├── signcerts
>    └── user
></pre>
>
>**1.16) Copy the tlscacert to the admin-ca msp tree**
>>`/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org1/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org1/msp`
>
><br>
>
>**1.17) Enroll the ORG ADMIN and populate the admincerts directory**
><br>Take a look at the comments in `login-admin.sh` in the CLI directory to understand how the enroll process and cert copying fills in the MSP tree.
>
>**NOTE: MUST RUN `login-admin.sh` with ". /" to capture env vars**
>>`. $FABRIC_CFG_PATH/setup/login-admin.sh`
>
><br>The `$FABRIC_CFG_PATH/orgs` directory tree should now look like the CLI tree shown on the [CRYPTO](../CRYPTO.md) page.
>
><br>
><br>
>
>### **Channel Artifacts**
>
>**1.18) Create the Channel Artifacts**
>
>>`$FABRIC_CFG_PATH/setup/generate_channel_artifacts.sh`
>
>The `genesis.block`, `channel.tx`, and `anchors.tx` were created in and used from the `FABRIC_CFG_PATH` directory.
>
>You might see the following warning from `configtxgen`.  This can be ignored for now - an update later will use the latest version of the `configtx.yaml` file to include the missing sections:
><br>`WARN 003 Default policy emission is deprecated, please include policy specificiations for the application group in configtx.yaml`
><br>
>
>Move the genesis block to the shared directory - this is needed to start the orderer (env var `ORDERER_GENERAL_GENESISFILE` in orderer)
>>`cp $FABRIC_CFG_PATH/genesis.block /shared`
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 1 ORDERER
**1.19) Start the org1 ORDERER service**
>`docker-compose -f org1/orderer/docker-compose.yaml up -d`

<br>

**1.20) Start a Bash session in the org1 ORDERER service**
>`docker exec -it org1-orderer bash`

#### The following step occurs inside the org1 ORDERER Bash session:
>The env vars should be set, including: `FABRIC_CA_CLIENT_HOME=/etc/hyperledger/orderer`
>
><br>
>
>**1.21) Enroll profile & fill MSP tree**
>
>Enroll the orderer profile to get the orderer's enrollment certificate (default profile):
>>`fabric-ca-client enroll -d -u https://org1-orderer:ordererpw@org1-ca:7054 -M $FABRIC_CA_CLIENT_HOME/msp`
>
>Copy the tlscacert to the orderer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $ORDERER_GENERAL_LOCALMSPDIR/cacerts/* -m $ORDERER_GENERAL_LOCALMSPDIR`
>
>Copy the admincert to the orderer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/org1-admin-cert.pem -m $ORDERER_GENERAL_LOCALMSPDIR`
>
><br>
>
>**1.22) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-orderer:ordererpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-orderer`
>
>
>Copy the TLS key and cert to the tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $ORDERER_GENERAL_TLS_CERTIFICATE -k $ORDERER_GENERAL_TLS_PRIVATEKEY`
>
><br>The msp directory tree should now look like the ORDERER tree shown on the [CRYPTO](../CRYPTO.md) page.
>
><br>
>
>**1.23) Start the orderer**
>
>>`orderer >> /shared/logs/orderer.log 2>&1 &`
>
>The log file is at: `/shared/logs/orderer.log`
><br>Ensure the orderer is running with `jobs`, if it does not show "Running", check the log for errors.  The log should end with something like "`...Beginning to serve requests`"
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 1 ANCHOR PEER
**1.24) Start the org1 PEER0 service**
>`docker-compose -f org1/peer0/docker-compose.yaml up -d`

<br>

**1.25) Start a Bash session in the org1 PEER0 service**
>`docker exec -it org1-peer0 bash`

#### The following step occurs inside the org1 PEER0 Bash session:
>The env vars should be set, including: `CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/msp`
>
><br>
>
>**1.26) Enroll profile & fill MSP tree**
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://org1-peer0:peerpw@org1-ca:7054 -M $CORE_PEER_MSPCONFIGPATH`
>
>Copy the tlscacert to the peer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH`
>
>Copy the admincert to the peer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/org1-admin-cert.pem -m $CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**1.27) Enroll the orderer to get TLS & Certs**
><br>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-peer0:peerpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE`
>
><br>The msp directory tree should now look like the PEER tree shown on the [CRYPTO](../CRYPTO.md) page.
>
><br>
>
>**1.28) Start the peer**
>
>>`peer node start >> /shared/logs/peer0.log 2>&1 &`
>
>The log file is at: `/shared/logs/peer0.log`
><br>Ensure the peer is running with `jobs`, if it does not show "Running", check the log for errors.
><br>
>
><br>
>
>End the Bash session with `exit`


<br>
<br>


## CHANNEL & CHAINCODE
**1.29) Start the org1 CLI (tools) service**
>`docker exec -it org1-cli bash`

#### The following steps occur inside the org1 CLI Bash session:
>Reload the environment variables and the admin profile
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. /etc/hyperledger/fabric/setup/login-admin.sh`
>
><br>
>
>**1.30) Create the Channel**
>>`peer channel create --logging-level=DEBUG -c mychannel -f $FABRIC_CFG_PATH/channel.tx $ORDERER_CONN_ARGS`
>
><br>
>
>**1.31) Join the Channel**
><br>You might need to retry to join the channel several times
>>`peer channel join -b mychannel.block`
>
><br>
>
>**1.32) Update the Channel with the new Anchor Peer**
>>`peer channel update -c mychannel -f $FABRIC_CFG_PATH/org1-anchors.tx $ORDERER_CONN_ARGS`
>
><br>
>
>**1.33) Install the Chaincode on the new Anchor Peer**
>>`peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go`
>
><br>
>
>**1.34) Instantiate the Chaincode on the new Anchor Peer**
>>`peer chaincode instantiate -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR('org1MSP.member')" $ORDERER_CONN_ARGS`
>
><br>
>
>**1.35) Test the Chaincode**
><br>Remember the initial value returned by a query
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>Invoke the chaincode to make an entry to the ledger
>>`peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS`
>
>Wait a few seconds to ensure that the ledger was updated before checking the new value
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>If the new value changed as expected, your network is complete with org1!
>
><br>
>
><br>
>
>End the Bash session with `exit`



<br>
<br>
<br>


# ORG 2
### Adding additional orgs at any time follows this same process

## ORG 2 CA SERVICE
**2.1) Start the org2 CA service**
>`docker-compose -f org2/ca/docker-compose.yaml up -d`

<br>

**2.2) Start a Bash session in the org2 CA service**
>`docker exec -it org2-ca bash`

#### The following step occurs inside the org2 CA Bash session:
>**2.3) Initialize the CA server**
>>`fabric-ca-server init -b org2-admin-ca:adminpw >>/shared/logs/ca.log 2>&1 &`
>
><br>
>
>**2.4) Copy the crypto material**
><br>Copy the Root CA Cert ONLY to the shared folder for production use.
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/org2-root-ca-cert.pem`
>
><br>
>
>**2.5) Start the CA Server**
>>`fabric-ca-server start >>/shared/logs/ca.log 2>&1 &`
>
>Check `ca.log` and ensure that the service is listening on the default port (7054).
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 2 CLI (tools) Service
**2.6) Start the org2 CLI (tools) service**
>`docker-compose -f org2/cli/docker-compose.yaml up -d`

<br>

**2.7) Start a Bash session in the org2 CLI service**
>`docker exec -it org2-cli bash`

#### The following steps occur inside the org2 CLI Bash session:
>If you exit and re-enter the Bash session, you might need to reset the environment variables.  Example: `export FABRIC_CFG_PATH=/etc/hyperledger/fabric`
>
><br>
>
>**2.8) Enroll the CA administrator**
><br>First, create the needed msp directory and set the environment variables needed.  The `$FABRIC_CFG_PATH` was set when the container was started (default: `/etc/hyperledger/fabric`)
>>`mkdir -p $FABRIC_CFG_PATH/orgs/org2/ca/org2-admin-ca`
><br>`export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/org2-root-ca-cert.pem`
><br>`export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/org2/ca/org2-admin-ca`
>
><br>Enroll the CA admin:
>>`fabric-ca-client enroll -d -u https://org2-admin-ca:adminpw@org2-ca:7054`
>
><br>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**2.9) Register the org administrator**
><br>The admin identity has the "admin" attribute which is added to ECert by default.  The other attributes are needed for this example chaincode settings.  Register the admin:
>>`fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"`
>
><br>
>
>**2.10) Register the peer profile**
>>`fabric-ca-client register -d --id.name org2-peer0 --id.secret peerpw --id.type peer`
>
><br>
>
>**2.11) (OPTIONAL) Register a user**
>>`fabric-ca-client register -d --id.name org2-user1 --id.secret userpw`
>
><br>
>
>**2.12) Generate client TLS cert and key pair for the peer commands**
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/org2/tls/org2-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/org2/tls/org2-peer0-cli-client.key`
>
><br>
>
>**2.13) Create the MSP directory tree**
><br>Get the root ca cert again and auto-create the org2 MSP tree
>>`fabric-ca-client getcacert -d -u https://org2-ca:7054 -M $FABRIC_CFG_PATH/orgs/org2/msp`
>
><br>
>
>**2.14) Copy the tlscacert to the admin-ca msp tree**
>>`/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/org2/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/org2/msp`
>
><br>
>
>**2.15) Enroll the ORG ADMIN and populate the admincerts directory**
><br>NOTE: MUST RUN `login-admin.sh` with ". /" to capture env vars
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. $FABRIC_CFG_PATH/setup/login-admin.sh`
>
><br>
>
>**2.16) Use the configtxgen tool to generate the org info JSON to join the channel**
><br>Move the configtx.yaml file to the FABRIC_CFG_PATH directory (see docker compose env vars)
>>`cp /etc/hyperledger/fabric/setup/configtx.yaml /etc/hyperledger/fabric/configtx.yaml`
>
>Generate the Org info using the configtxgen tool for joining the existing channel
>>`configtxgen -channelID mychannel -printOrg org2 > org2.json`
>
>pass org2.json to common folder for use by authorizing org(s)
>>`cp org2.json /shared/org2.json`
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## MANUAL TRANSFER
**2.17) MANUAL TRANSFER org2 -> org1**
- Copy created `.json` file to org1 `/shared` directory

<br>

**2.18) MANUAL TRANSFER org1 -> org2**
- Copy `org1-root-ca-cert.pem` to org2 `/shared` directory

<br>
<br>

## ORG 2 ANCHOR PEER
**2.19) Start the org2 PEER0 service**
>`docker-compose -f org2/peer0/docker-compose.yaml up -d`

<br>

**2.20) Start a Bash session in the org2 PEER0 service**
>`docker exec -it org2-peer0 bash`

#### The following step occurs inside the org2 PEER0 Bash session:
>The env vars should be set, including: `CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/msp`
>
><br>
>
>**2.21) Enroll profile & fill MSP tree**
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://org2-peer0:peerpw@org2-ca:7054 -M $CORE_PEER_MSPCONFIGPATH`
>
>Copy the tlscacert to the peer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH`
>
>Copy the admincert to the peer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/org2-admin-cert.pem -m $CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**2.22) Enroll the orderer to get TLS & Certs**
><br>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-peer0:peerpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE`
>
><br>
>
>**2.23) Start the peer**
>
>>`peer node start >> /shared/logs/peer0.log 2>&1 &`
>
>The log file is at: `/shared/logs/peer0.log`
><br>Ensure the peer is running with `jobs`, if it does not show "Running", check the log for errors.
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 1 CLI - UPGRADE CHAINCODE
**2.24) Start a Bash session in the org1 CLI service**
>`docker exec -it org1-cli bash`

#### The following step occurs inside the org1 CLI Bash session:
>Reset the env vars & profile:
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. /etc/hyperledger/fabric/setup/login-admin.sh`
<br>`CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"`
>
><br>
>
>**2.25) Install jq (command-line JSON processor)**
>>`apt-get -y update && apt-get -y install jq`
>
><br>
>
>**2.26) Fetch the config block for the channel**
>>`peer channel fetch config config_block.pb -c mychannel $ORDERER_CONN_ARGS`
>
>Convert it to json (output to `config.json`)
>>`configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json`
>
><br>
>
>**2.27) Create Config Update Envelope**
><br>Modify the configuration to append org2
>>`jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"org2":.[1]}}}}}' config.json /shared/org2.json > modified_config.json`
>
>Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to update_in_envelope.pb
>>`configtxlator proto_encode --input config.json --type common.Config >original_config.pb`
<br>`configtxlator proto_encode --input modified_config.json --type common.Config >modified_config.pb`
<br>`configtxlator compute_update --channel_id mychannel --original original_config.pb --updated modified_config.pb >config_update.pb`
<br>`configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json`
<br>`echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json`
<br>`configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"update_in_envelope.pb"`
>
><br>
>
>**2.28) Sign the Update Envelope**
>>`peer channel signconfigtx -f update_in_envelope.pb`
>
>Copy the envelope to the common directory and pass to other authorizing admins (if needed)
>>`cp update_in_envelope.pb /shared/update_in_envelope.pb`
>
><br>
>
>**2.29) Update Channel**
><br>After ALL needed admins have signed the update envelope, update the channel
>>`peer channel update -f update_in_envelope.pb -c mychannel $ORDERER_CONN_ARGS`
>
><br>
>
>**2.30) Install Chaincode**
><br>Be sure to iterate the chaincode version before installation
>>`peer chaincode install -n mycc -v 2.0 -l golang -p github.com/hyperledger/fabric-samples/chaincode/abac/go`
>
><br>
>
>**2.31) Upgrade Chaincode**
><br>NOTES:
>- Be sure to use the same chaincode version used on the install
>- Use ".member" NOT ".peer" - a later update will use NodeOUs to enable use of ".peer", ".client", etc.
>
>>`peer chaincode upgrade -C mychannel -n mycc -v 2.0 -c '{"Args":["init","a","5000","b","8000"]}' -P "OR('org1MSP.member','org2MSP.member')" $ORDERER_CONN_ARGS`
>
><br>
>
>**2.32) Test Chaincode**
><br>First run a query to check the current ledger value
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>Run an invoke to change the value
>>`peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS`
>
>Wait a few seconds to ensure the ledger is updated, then check the value to ensure it changed
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>If the new value changed as expected, org1 has been successfully updated!
>
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## ORG 2 CLI - INSTALL CHAINCODE
**2.33) Start a Bash session in the org2 CLI service**
>`docker exec -it org2-cli bash`

#### The following step occurs inside the org2 CLI Bash session:
>Reset the env vars & profile:
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. /etc/hyperledger/fabric/setup/login-admin.sh`
>
><br>
>
>**2.34) Fetch the config block for the channel**
>>`peer channel fetch 0 mychannel.block -c mychannel $ORDERER_CONN_ARGS`
>
><br>
>
>**2.35) Join the channel**
>>`peer channel join -b mychannel.block`
>
><br>
>
>**2.36) Install Chaincode**
><br>Be sure to match the chaincode version with the other org chaincode install
>>`peer chaincode install -n mycc -v 2.0 -l golang -p github.com/hyperledger/fabric-samples/chaincode/abac/go`
>
><br>
>
>**2.37) Test Chaincode**
><br>First run a query to check the current ledger value
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>Run an invoke to change the value
>>`peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_CONN_ARGS`
>
>Wait a few seconds to ensure the ledger is updated, then check the value to ensure it changed
>>`peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'`
>
>If the new value changed as expected, org2 has been successfully updated!
>
><br>
>
><br>
>
>End the Bash session with `exit`

<br>
<br>
