# Centralized HLF Network (simplified)
This network runs on a solo orderer (hosted by a single org) and static docker containers (no swarm, etc.)

---
## CHECK CUSTOM CHANGES (each org):

`fabric-ca-server-config.yaml`:
 - version: (ensure usable by ca server image)
 - ca: name:
 - registry: identities: name:, pass:
 - tls:
 - debug:
 - affiliations: (list orgs, deptartments, teams)
 - csr:

 `fabric-ca-client-config.yaml`:
 - url:
 - csr:

<br>
<br>
<br>

# PROCEDURE
## ORDERER ORG
**Start the CA service**
<br>1.1) /ca: `docker-compose up`
<br>.
<br>├── IssuerPublicKey
<br>├── IssuerRevocationPublicKey
<br>├── ca-cert.pem
<br>├── logs
<br>│   └── ca.log
<br>├── msp
<br>│   └── keystore
<br>│       ├── 6c1b53d5c5e72f82c5ee6ea44fc2181afc57b2f9be00c5307e8db79dab85893d_sk
<br>│       ├── IssuerRevocationPrivateKey
<br>│       └── IssuerSecretKey
<br>└── tls-cert.pem

**Start the CLI (tools) service**
<br>1.2) /cli: `docker-compose up`

**Enroll the CA administrator**
<br>1.3) INSIDE cli: `fabric-ca-client enroll -d -u https://ordererOrg-ca-admin:adminpw@ordererOrg-ca:7054`

**Register the orderer**
<br>1.4) INSIDE cli: `fabric-ca-client register -d --id.name orderer --id.secret ordererpw --id.type orderer`

**Register the orderer administrator**
<br>The admin identity has the "admin" attribute which is added to ECert by default:
<br>1.5) INSIDE cli: `fabric-ca-client register -d --id.name admin-ordererOrg --id.secret adminpw --id.attrs "admin=true:ecert"`

<br>
<br>

## PEER ORGS
Each peer org needs its own MSP and CA

<br>
<br>

### **ORG1:**
**Start the CA service**
<br>2.1.1) /ca: `docker-compose up`

**Start the CLI (tools) service**
<br>2.1.2) /cli: `docker-compose up`

**Enroll the CA administrator**
<br>2.1.3) INSIDE cli: `fabric-ca-client enroll -d -u https://org1-ca-admin:adminpw@org1-ca:7054`

**Register a peer**
<br>2.1.4) INSIDE cli: `fabric-ca-client register -d --id.name org1-peer0 --id.secret peerpw --id.type peer`

**Register a peer administrator**
<br>The admin identity has the "admin" attribute which is added to ECert by default:
<br>2.1.5) INSIDE cli: `fabric-ca-client register -d --id.name org1-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"`

**Register an org user**
<br>2.1.6) INSIDE cli: `fabric-ca-client register -d --id.name org1-user0 --id.secret userpw`

<br>
<br>

### **ORG2:**
**Start the CA service**
<br>2.2.1) /ca: `docker-compose up`

**Start the CLI (tools) service**
<br>2.2.2) /cli: `docker-compose up`

**Enroll the CA administrator**
<br>2.2.3) INSIDE cli: `fabric-ca-client enroll -d -u https://org2-ca-admin:adminpw@org2-ca:7054`

**Register a peer**
<br>2.2.4) INSIDE cli: `fabric-ca-client register -d --id.name org2-peer0 --id.secret peerpw --id.type peer`

**Register a peer administrator**
<br>The admin identity has the "admin" attribute which is added to ECert by default:
<br>2.2.5) INSIDE cli: `fabric-ca-client register -d --id.name org2-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"`

**Register an org user**
<br>2.2.6) INSIDE cli: `fabric-ca-client register -d --id.name org2-user0 --id.secret userpw`

<br>
<br>

## CA Certs
