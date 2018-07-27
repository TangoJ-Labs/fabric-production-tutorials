# Decentralized HLF Network (simplified)
This network runs on a solo orderer and static docker containers (no swarm, etc.)

---
## NOTES
In a decentralized service, each org needs its own CA and MSP hierarchy.
<br>
<br>
IF YOU MODIFY THE ORG NAMES, change the below commands as needed, and be sure to check the docker compose files and the config files:
>`fabric-ca-server-config.yaml`:
>- version: (ensure usable by ca server image)
>- ca: name:
>- registry: identities: name:, pass:
>- tls:
>- debug:
>- affiliations: (list orgs, deptartments, teams)
>- csr:
>
>`fabric-ca-client-config.yaml`:
>- url:
>- csr:
---

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
<br>From the ...decentralized_solo/org1/ca dir:
>`docker-compose up -d`

An MSP directory should have been created in the CA home directory:
<br><pre>.
<br>├── IssuerPublicKey
<br>├── IssuerRevocationPublicKey
<br>├── ca-cert.pem
<br>└── msp
<br>    └── keystore
<br>        ├── {...}_sk
<br>        ├── IssuerRevocationPrivateKey
<br>        └── IssuerSecretKey
<br></pre>
NOTE: Because we included the `fabric-ca-server-config.yaml` file (rather than allowing it to be auto-generated), the `ca.sh` script does not call `fabric-ca-server init`.  The `registry: identities:` section of the config file contains the bootstrap admin profile details.

<br>

**1.2) Start a Bash session in the CA service**
>`docker exec -it org1-ca bash`

#### The following step occurs inside the CA Bash session:
>**1.3) Copy the crypto material**
><br>This will copy the certificate to the organization common folder for use among the org.  This file is listed in the CLI config file (fabric-ca-client-config.yaml) in the `tls: certfiles:` section to include the cert as a trusted root certificate (needed to `enroll` from the CLI).  You can also set this via the `FABRIC_CA_CLIENT_TLS_CERTFILES` environment variable.
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /data/org1-ca-cert.pem`
><br>
>

<br>
<br>

## CLI (tools) Service
**1.4) Start the CLI (tools) service**
<br>From the ...decentralized_solo/org1/cli dir:
>`docker-compose up -d`

<br>

**1.5) Start a Bash session in the CLI service**
>`docker exec -it org1-cli bash`

#### The following steps occur inside the CLI Bash session:
>**1.6) Enroll the CA administrator**
<br>This will create a client config file (if not preexisting), and create an msp directory.
>>`fabric-ca-client enroll -d -u https://org1-admin-ca:adminpw@org1-ca:7054`
>
><br>An MSP directory should have been created in the CLI home directory.  The `cacerts/org1-ca-7054.pem` is the same certificate as the ca-cert.pem (renamed org1-ca-7054.pem) we created in the CA and used in the CLI config file:
><br><pre>.
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
><br>Get the cert again (same cert), but direct it to a new directory to fill it out with a new format (the `/data` dir in this case).
>>`fabric-ca-client getcacert -d -u https://org1-ca:7054 -M /data/orgs/org1/msp`
>
>This script will move the needed crypto material from the cli home directory msp to the new msp tree. If you changed the org name, or other details, check the script for needed changes.
>>`/etc/hyperledger/cli/setup/generate_msp.sh`
>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**1.8) Register the org administrator**
<br>The admin identity has the "admin" attribute which is added to ECert by default.
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
>>`export FABRIC_CFG_PATH=/etc/hyperledger/cli/setup`
>
>>`/etc/hyperledger/cli/setup/generate_channel_artifacts.sh`
>
>
><br>
>

<br>
<br>

## ORDERER
**1.13) Start the ORDERER service**
<br>From the ...decentralized_solo/org1/orderer dir:
>`docker-compose up -d`

<br>

**1.14) Start a Bash session in the ORDERER service**
>`docker exec -it org1-orderer bash`

#### The following step occurs inside the ORDERER Bash session:
>**1.15) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert:
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-orderer:ordererpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-orderer`
>
>Enroll again to get the orderer's enrollment certificate (default profile)
>>`fabric-ca-client enroll -d -u https://org1-orderer:ordererpw@org1-ca:7054 -M /etc/hyperledger/orderer/msp`
>
>Copy the crypto material to the msp & tls directories
>>`/etc/hyperledger/orderer/setup/copy_certs.sh`
>
><br>
>
>**1.16) Start the orderer**
><!-- >>`env | grep ORDERER` -->
>
>>`orderer >> /data/logs/orderer.log 2>&1 &`

<br>
<br>

## ANCHOR PEER
**1.17) Start the PEER0 service**
<br>From the ...decentralized_solo/org1/peer0 dir:
>`docker-compose up -d`

<br>

**1.18) Start a Bash session in the PEER0 service**
>`docker exec -it org1-peer0 bash`

#### The following step occurs inside the PEER0 Bash session:
>**1.19) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert:
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://org1-peer0:peerpw@org1-ca:7054 -M /tmp/tls --csr.hosts org1-peer0`
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://org1-peer0:peerpw@org1-ca:7054 -M /opt/gopath/src/github.com/hyperledger/fabric/peer/msp`
>
>Copy the crypto material to the msp & tls directories
>>`/opt/gopath/src/github.com/hyperledger/fabric/peer/setup/copy_certs.sh`
>
><br>
>
>**1.20) Start the orderer**
><!-- >>`env | grep CORE` -->
>
>>`peer node start >> /data/logs/peer0.log 2>&1 &`


<br>
<br>

# CHANNEL - CREATE, JOIN, ADD ANCHOR PEER
## Create the Channel
**1.21) Start the CLI (tools) service**
<br>From the ...decentralized_solo/org1/cli dir:
>`docker exec -it org1-cli bash`

#### The following steps occur inside the CLI Bash session:
>**1.22) Create the Channel**


<br>
<br>

# ORG 2



<br>
<br>
