# Decentralized HLF Network (simplified)
This network runs on a solo orderer (for each org) and static docker containers (no swarm, etc.)

---
## NOTES
- A "decentralized" service implies equality among members, but since we are using a solo Orderer, only one Orderer node can exist, so a single (in this case the first) organization will host the Orderer.
- In any decentralized service, each org needs its own CA (Certificate Authority) to issue cryptographic materials.
<br>
<br>
- Most services (containers) also include a `*_auto.sh` file in their directory.  You can use these scripts (change the docker-compose file `command:` section) to more quickly setup the network.  The manual steps are listed below for educational purposes.
<br>
<br>
- We will create a complete MSP tree in the organization common directory (`/data` in our case).  This MSP tree will resemble the MSP tree created by `cryptogen` utility used in other Hyperledger Fabric examples.  This MSP tree is for educational purposes **ONLY**.  In production you will not create an entire MSP tree in one location exposing all private keys to misuse.  In production you will leave the private keys in each service (container), and only share the public certs when needed.  While we are creating the common MSP tree for educational purposes, we will also follow production protocol and create parallel directories to hold the shared public certificates.  Feel free to skip the steps to create the common MSP tree - we will not use that material (again, it is just for educational purposes in order to explain how using the CA service compares to the `cryptogen` utility used in most Hyperledger examples).
<br>
<br>
- IF YOU MODIFY THE ORG NAMES, change the commands in this tutorial as needed, and be sure to check the `docker-compose.yaml` files and the `configtx.yaml` files.

---

<br>
<br>

# SETUP - DOCKER NETWORK
Start the network separately to ensure the network name is consistent in all secondary docker-compose files.
<br>
<br>**0.1) Start the Docker Network**
>`docker network create decentralized_solo`

(you can check the running docker networks with `docker network list`)

<br>
<br>

# ORG 1
## CA Service
**1.1) Start the CA service**
>`cd {your repo home}/decentralized_solo/org1/ca`

>`docker-compose up -d`

NOTE: If you explore the container filesystem, a server cert and key are created in a `.../fabric-ca-server` sibling directory to the home directory.  This material can be ignored for our purposes.  The CSR details on this material is default, and we will not use this crypto material for our network.

**1.2) Start a Bash session in the CA service**
>`docker exec -it org1-ca bash`

#### The following step occurs inside the CA Bash session:
>**1.3) Initialize the CA server**
>>`fabric-ca-server init -b org1-admin-ca:adminpw >>/data/logs/ca.log 2>&1 &`
>
>The `>>...` redirect will hide the stdout and stderror from your command line.  You will need to open `ca.log` to check for errors.  You can change the `admin:adminpw` parameter to whatever admin username / password you want for the CA server admin.
>
>A `fabric-ca-server-config.yaml` file, root CA certificate `ca-cert.pem`, and `.../keystore` directory with private keys will be created at the server home directory (set by `FABRIC_CA_SERVER_HOME` in the docker-compose file).  We will override many of the config file CSR settings with environmental variables (the config file will still show default settings).  The entire structure should resemble:
>
><pre style="line-height: 0.7;">
>.
>├── fabric-ca-server.db
>├── fabric-ca-server-config.yaml
>├── IssuerPublicKey
>├── IssuerRevocationPublicKey
>├── ca-cert.pem                        <--- We want to save this Root CA Cert to MSP tree
>└── msp
>    └── keystore
>        ├── {...}_sk                   <--- We want to save this Root CA priv key to MSP tree
>        ├── IssuerRevocationPrivateKey
>        └── IssuerSecretKey
></pre>
>
><br>
>
>**1.4) Copy the crypto material**
>
>OPTIONAL: FULL MSP TREE
>>`$FABRIC_CA_SERVER_HOME/setup/msp.sh`
>
>This will copy the Root CA certificate and associated private key to the common directory MSP tree.  Remember that this common directory MSP tree is for educational purposes and would not be created in a production environment.
>
>Copy the Root CA Cert ONLY to the common folder for production use.
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /data/org1-root-ca-cert.pem`
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
>>`fabric-ca-server start >>/data/logs/ca.log 2>&1 &`
>
>Again, this will redirect all output to the log file.  Check `ca.log` and ensure that the service is listening on the default port (7054).
>
>
>End the Bash session with `exit`

<br>
<br>

## CLI (tools) Service
**1.4) Start the CLI (tools) service**
>`cd {your repo home}/decentralized_solo/org1/cli`

>`docker-compose up -d`

<br>

**1.5) Start a Bash session in the CLI service**
>`docker exec -it org1-cli bash`

#### The following steps occur inside the CLI Bash session:
>**1.6) Enroll the CA administrator**
<br>This will create a client config file (if not preexisting), and create an msp directory:
>>`fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054`
>
><br>An MSP directory should have been created in the CLI home directory.  The `cacerts/org1-ca-7054.pem` is the same certificate as the ca-cert.pem (renamed org1-ca-cert.pem) we created in the CA and passed to the common `/data` directory to be used in the CLI config file.
><br><pre style="line-height: 0.7;">.
><br>└── msp
><br>    ├── cacerts
><br>    │   └── org1-ca-7054.pem
><br>    ├── keystore
><br>    │   ├── {...}_sk
><br>    ├── signcerts
><br>    │   └── cert.pem
><br>    └── user
><br></pre>
><br>
>
>**1.7) Create the MSP directory tree**
><br>Get the cert again (same cert), but direct it to a common directory to fill out an msp tree (the `/data` dir in this case):
>>`fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /etc/hyperledger/fabric/msp`
>
>This script will move the needed crypto material from the cli home directory msp to the common (`/data`) msp tree. If you changed the org name, or other details, check the script for needed changes:
>>`/etc/hyperledger/fabric/setup/generate_msp.sh`
>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**1.8) Register the org administrator**
<br>The admin identity has the "admin" attribute which is added to ECert by default.  Register the admin:
>>`fabric-ca-client register -d --id.name org1-admin-orderer --id.secret adminpw --id.attrs "admin=true:ecert"`
>
>OR (potential attributes - see [docs](https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#registering-a-new-identity) for more):
>
>>`fabric-ca-client register -d --id.name org1-admin-peer --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"`
>
><br>
>
>**1.9) Register the orderer**
>>`fabric-ca-client register -d --id.name org1-orderer --id.secret ordererpw --id.type orderer`
>
><br>
>
>**1.10) Register the peer**
>>`fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer`
>
><br>
>
>**1.11) Register a user**
>>`fabric-ca-client register -d --id.name org1-user1 --id.secret userpw`
>
><br>
><br>
>
>### **Channel Artifacts**
>
>**1.12) Create the Channel Artifacts**
>>`export FABRIC_CFG_PATH=/etc/hyperledger/fabric`
>
>>`/etc/hyperledger/fabric/setup/generate_channel_artifacts.sh`
>
>The `genesis.block`, `channel.tx`, and `anchors.tx` should have been added to the `/data` common directory.
><br>
>
><br>
>The `/data` common directory for org1 should now look like:
><br><pre style="line-height: 0.7;">.
><br>├── anchors.tx
><br>├── channel.tx
><br>├── genesis.block
><br>├── logs
><br>│   ├── ca.log
><br>│   └── cli.log
><br>├── org1-ca-cert.pem
><br>├── orgs
><br>│   └── org1
><br>│       ├── admin
><br>│       │   └── msp
><br>│       │       ├── admincerts
><br>│       │       │   └── cert.pem
><br>│       │       ├── cacerts
><br>│       │       │   └── org1-ca-7054.pem
><br>│       │       ├── keystore
><br>│       │       │   └── {...}_sk
><br>│       │       ├── signcerts
><br>│       │       │   └── cert.pem
><br>│       │       └── user
><br>│       └── msp
><br>│           ├── admincerts
><br>│           │   └── cert.pem
><br>│           ├── cacerts
><br>│           │   └── org1-ca-7054.pem
><br>│           ├── keystore
><br>│           ├── signcerts
><br>│           ├── tlscacerts
><br>│           │   └── org1-ca-7054.pem
><br>│           └── user
><br>└── tls
><br></pre>
>
>End the Bash session with `exit`

<br>
<br>

## ORDERER
**1.13) Start the ORDERER service**
>`cd {your repo home}/decentralized_solo/org1/orderer`

>`docker-compose up -d`

<br>

**1.14) Start a Bash session in the ORDERER service**
>`docker exec -it org1-orderer bash`

#### The following step occurs inside the ORDERER Bash session:
>Ensure you're logged in as the administrator (if not, run `enroll` again)
><br>
><br>
>
>**1.15) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert:
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-orderer:ordererpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-orderer`
>
>The key & cert were stored in a temporary location for use later in this section.
>
>Enroll again to get the orderer's enrollment certificate (default profile):
>>`fabric-ca-client enroll -d -u https://org1-orderer:ordererpw@org1-ca:7054 -M /etc/hyperledger/orderer/msp`
>
>Copy the tls material to the common `/data` directory, and the msp material to the local (orderer) msp tree:
>>`/etc/hyperledger/orderer/setup/copy_certs.sh`
>
><br>
>
>**1.16) Start the orderer**
><!-- >>`env | grep ORDERER` -->
>
>>`env | grep ORDERER`
>
>>`orderer >> /data/logs/orderer.log 2>&1 &`
>
>The log file is at: `/data/logs/orderer.log`
><br>Ensure the orderer is running with `jobs`, if it does not show "Running", check the log for errors.
>
>End the Bash session with `exit`

<br>
<br>

## ANCHOR PEER
**1.17) Start the PEER0 service**
>`cd {your repo home}/decentralized_solo/org1/peer0`

>`docker-compose up -d`

<br>

**1.18) Start a Bash session in the PEER0 service**
>`docker exec -it org1-peer0 bash`

#### The following step occurs inside the PEER0 Bash session:
>Ensure you're logged in as the administrator (if not, run `enroll` again)
><br>
><br>
>
>**1.19) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert:
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-peer1:peerpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-peer1`
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://org1-peer1:peerpw@org1-ca:7054 -M /opt/gopath/src/github.com/hyperledger/fabric/peer/msp`
>
>Copy the tls material to the common `/data` directory, and the msp material to the local (peer0) msp tree:
>>`/opt/gopath/src/github.com/hyperledger/fabric/peer/setup/copy_certs.sh`
>
><br>
>
>**1.20) Start the orderer**
><!-- >>`env | grep CORE` -->
>
>>`env | grep CORE`
>
>>`peer node start >> /data/logs/peer0.log 2>&1 &`
>
>The log file is at: `/data/logs/peer0.log`
><br>Ensure the peer is running with `jobs`, if it does not show "Running", check the log for errors.
>
>End the Bash session with `exit`


<br>
<br>

# CHANNEL - CREATE, JOIN, ADD ANCHOR PEER
## Create the Channel
**1.21) Start the CLI (tools) service**
>`cd {your repo home}/decentralized_solo/org1/cli`

>`docker exec -it org1-cli bash`

#### The following steps occur inside the CLI Bash session:
>Ensure you're logged in as the administrator (if not, run `enroll` again)
><br>
><br>
>
>>`fabric-ca-client enroll -d -u https://org1-admin:adminpw@org1-ca:7054`
>
>**1.22) Create the Channel**
>>`peer channel create --logging-level=DEBUG -c dsolo -f /data/channel.tx -o org1-orderer:7050 --tls --cafile /data/org1-ca-cert.pem --clientauth --keyfile /data/tls/org1-peer0-client.key --certfile /data/tls/org1-peer0-client.crt`
>
>
>
>End the Bash session with `exit`


<br>
<br>

# ORG 2
### Adding additional orgs at any time follows this same process




<br>
<br>
