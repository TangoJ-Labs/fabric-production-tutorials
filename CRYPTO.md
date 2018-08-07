# Hyperledger Cryptographic Material & MSP Structure

## /MSP

Here is a common MSP structure.

Keep in mind:
>- The `/tls*` and `/admincerts` folders are manually created (first time the CLI is started - see first CLI startup steps)
>
>- `/tls` certs are the respective (root or intermediate) PEM-encoded trusted cert for the orderering endpoint (if unchanged, same as the original `ca-cert.pem` from starting the CA that was sent to the org's common directory (e.g. `/data`).  This cert is the same as the `/cacerts/{...}.pem` cert).  IF THE CA CERT IS PLACED ON THE REJECTION LIST, THIS MUST BE UPDATED WITH THE NEW CA CERT.
>
>- The `/admincerts` cert is the `/signcert/cert.pem` for the admin, when it was enrolled.  Because this folder is manually created, IT MUST BE UPDATED EVERY TIME THE ADMIN IS ENROLLED (since the `signcert/cert.pem` public cert will change for every `enroll` call)
<pre>
.
└── org1
    ├── admin
    │   ├── fabric-ca-client-config.yaml <--- config file for enrolled user (only default values?)
    │   └── msp
    │       ├── admincerts
    │       │   └── cert.pem         <--- Public cert for admin - paired to a private '_sk' key in /keystore - e.g. org1-admin)
    │       ├── cacerts
    │       │   └── org1-ca-7054.pem <--- PEM-encoded trusted certificate for the ordering endpoint
    │       ├── keystore
    │       │   ├── {...}_sk         <--- Private key (paired to a public cert.pem - e.g. org1-admin)
    │       │   └── {...}_sk         <--- Private key (paired to a public cert.pem - e.g. org1-user1)
    │       ├── signcerts
    │       │   └── cert.pem         <--- Public cert (currently logged in (enrolled) user - paired to a private '_sk' key in /keystore - e.g. org1-user1 or org1-admin)
    │       └── user
    └── msp
        ├── admincerts
        │   └── cert.pem             <--- Public cert for admin - paired to a private '_sk' key in /keystore - e.g. org1-admin)
        ├── cacerts
        │   └── org1-ca-7054.pem     <--- PEM-encoded trusted certificate for the ordering endpoint
        ├── keystore
        ├── signcerts
        ├── tlscacerts
        │   └── org1-ca-7054.pem     <--- PEM-encoded trusted certificate for the ordering endpoint
        └── user
</pre>

## /TLS
TLS file paris for mutual TLS communication
>- The TLS directory may have numerous tls certs/keys at any one time.  They could even all be active at the same time. Pairs might have been placed on the rejection list (crl), and will no longer work.
>
>- These pairs were likely created during the peer startup procedures (see manual process steps), and were named manually, so keep track of which pairs match to which nodes.
>
>- New pairs can be created by using the `fabric-ca-client enroll --enrollment.profile tls ...` (see peer startup steps for examples).  They will be dumped in the directory specified in the `enroll` request, and must be manually copied and named to the org's common directory (e.g. `/data`) for mutual TLS communication.
<pre>
.
├── org1-peer0-cli-client.crt  <--- `enroll` dumped this in specified `/signcerts` directory as a `.pem` file
├── org1-peer0-cli-client.key  <--- `enroll` dumped this in specified `/keystore` directory as a `_sk` file
├── org1-peer0-client.crt
└── org1-peer0-client.key
</pre>

<br>
<br>

### Usage example:
`peer chaincode invoke -C mychannel -n mychaincode -c '{"Args":["invoke","a","b","10"]}' -o org1-orderer:7050 --tls --cafile /data/org1-ca-cert.pem --clientauth --keyfile /data/tls/org1-peer0-client.key --certfile /data/tls/org1-peer0-client.crt`

<br>
<br>

### More information:
- Mutual TLS: https://www.codeproject.com/Articles/326574/An-Introduction-to-Mutual-SSL-Authentication
![Mutual TLS][mtls]

<br>

- Mutual Authentication Vulnerability - Reflection Attack: https://www.youtube.com/watch?v=Y6d-fRMJObI
![Reflection Attack][reflection]

[mtls]: https://www.codeproject.com/KB/IP/326574/mutualssl_small.png "Mutual TLS"
[reflection]: https://i.ytimg.com/vi/Y6d-fRMJObI/maxresdefault.jpg "Reflection Attack"


<br>
<br>
<br>

# Production MSP Structure - Nodes (Servers / Containers) Separated (Draft)

### CA
<pre style="line-height: 0.7;">
FABRIC_CA_SERVER_HOME (org1-ca)
├── fabric-ca-server.db
├── fabric-ca-server-config.yaml
├── IssuerPublicKey
├── IssuerRevocationPublicKey
├── ca-cert.pem
└── msp
    └── keystore
        ├── {...}_sk
        ├── IssuerRevocationPrivateKey
        └── IssuerSecretKey
</pre>
<br>

### CLI
<pre style="line-height: 0.7;">
FABRIC_CA_CLIENT_HOME (org1-cli)
├── org1
│   ├── ca
│   │   └── msp                                 <--- from org1-admin-ca enroll
│   ├── fabric-ca-client-config.yaml
│   ├── msp                                     <--- from "fabric-ca-client getcacert"
│   │   ├── admincerts                          <--- MANUAL: copy org1-admin cert
│   │   ├── cacerts                             <--- from "fabric-ca-client getcacert"
│   │   ├── keystore
│   │   ├── signcerts
│   │   ├── tlscacerts                          <--- MANUAL: copy cacerts dir contents
│   │   └── user
│   │       ├── org1-admin
│   │       │   ├── fabric-ca-client-config.yaml
│   │       │   └── msp
│   │       │       ├── admincerts              <--- MANUAL: copy org1-admin cert (configtxgen uses CORE_PEER_MSPCONFIGPATH)
│   │       │       ├── cacerts                 <--- matches Root CA Cert
│   │       │       ├── keystore                <--- org1-admin private key
│   │       │       ├── signcerts               <--- org1-admin public cert
│   │       │       └── user                    <--- empty (auto-created)
│   │       └── org1-user-test
│   │           ├── fabric-ca-client-config.yaml
│   │           └── msp
│   │               ├── admincerts              <--- MANUAL: add an org admin cert
│   │               ├── cacerts                 <--- matches Root CA Cert
│   │               ├── keystore                <--- org1-user-test private key
│   │               ├── signcerts               <--- org1-user-test public cert
│   │               └── user                    <--- empty (auto-created)
│   └── tls
│       
└── org2
    ├── ca
    └── tls
</pre>
<br>

### ORDERER
<pre style="line-height: 0.7;">
FABRIC_CA_CLIENT_HOME (org1-orderer)
├── configtx.yaml
├── core.yaml
├── orderer.yaml
├── msp
│   ├── admincerts      <--- add an org admin cert (for orderer start)
│   ├── cacerts
│   ├── config.yaml
│   ├── keystore
│   ├── signcerts
│   ├── tlscacerts      ?<--- copy cacerts dir contents
│   └── tlsintermediatecerts
└── tls                 ?<--- add tls crt and key (for orderer start)
</pre>
<br>

### PEER
<pre style="line-height: 0.7;">
FABRIC_CA_CLIENT_HOME (org1-peer0)
├── fabric-ca-client-config.yaml
├── msp
│   ├── admincerts      <--- add an org admin cert (for peer start)
│   ├── cacerts
│   ├── config.yaml
│   ├── keystore
│   ├── signcerts
│   ├── tlscacerts      <--- copy cacerts dir contents
│   └── user
└── tls                 <--- add tls crt and key (for peer start)
</pre>
<br>

### CLIENT
<pre style="line-height: 0.7;">
FABRIC_CA_CLIENT_HOME (org1-client1)
├── org1-user1
│   ├── fabric-ca-client-config.yaml
│   ├── msp
│   │   ├── cacerts
│   │   ├── keystore
│   │   ├── signcerts
│   │   └── user
│   └── tls
└── org1-user2
    ├── fabric-ca-client-config.yaml
    ├── msp
    │   ├── cacerts
    │   ├── keystore
    │   ├── signcerts
    │   └── user
    └── tls
</pre>


<br>
<br>
<br>


### First-Network MSP Directories:

<pre style="line-height: 0.7;">
.
└── org1
   ├── ca
   ├── msp
   │   ├── admincerts
   │   ├── cacerts
   │   ├── config.yaml
   │   └── tlscacerts
   ├── orderers
   │   └── orderer
   │       ├── msp
   │       │   ├── admincerts
   │       │   ├── cacerts
   │       │   ├── config.yaml
   │       │   ├── keystore
   │       │   ├── signcerts
   │       │   └── tlscacerts
   │       └── tls
   ├── peers
   │   └── org1-peer0
   │       ├── msp
   │       │   ├── admincerts
   │       │   ├── cacerts
   │       │   ├── config.yaml
   │       │   ├── keystore
   │       │   ├── signcerts
   │       │   └── tlscacerts
   │       └── tls
   ├── tlsca
   └── users
       ├── org1-admin
       │   ├── msp
       │   │   ├── admincerts
       │   │   ├── cacerts
       │   │   ├── keystore
       │   │   ├── signcerts
       │   │   └── tlscacerts
       │   └── tls
       └── org1-user1
           ├── msp
           │   ├── admincerts
           │   ├── cacerts
           │   ├── keystore
           │   ├── signcerts
           │   └── tlscacerts
           └── tls
</pre>



### First-Network MSP Structure:

<pre style="line-height: 0.7;">
.
└── org1
   ├── ca
   │   ├── {...}_sk                    <---  KEY: Root CA priv key
   │   └── ca-cert.pem                 <--- CERT: Root CA
   ├── msp
   │   ├── admincerts
   │   │   └── cert.pem                <--- CERT: User Cert: Admin
   │   ├── cacerts
   │   │   └── ca-cert.pem             <--- CERT: Root CA
   │   ├── config.yaml
   │   └── tlscacerts
   │       └── tlsca-cert.pem          <--- CERT: Root TLS CA Cert
   ├── orderers
   │   └── orderer
   │       ├── msp
   │       │   ├── admincerts
   │       │   │   └── cert.pem        <--- CERT: User Cert: Admin
   │       │   ├── cacerts
   │       │   │   └── ca-cert.pem     <--- CERT: Root CA
   │       │   ├── config.yaml
   │       │   ├── keystore
   │       │   │   └── {...}_sk        <---  KEY: Orderer Cert priv key
   │       │   ├── signcerts
   │       │   │   └── cert.pem        <--- CERT: Orderer Cert
   │       │   └── tlscacerts
   │       │       └── tlsca-cert.pem  <--- CERT: Root TLS CA Cert
   │       └── tls
   │           ├── tlsca-cert.pem      <--- CERT: Root TLS CA Cert
   │           ├── server.crt          <--- CERT: Orderer TLS Cert
   │           └── server.key          <---  KEY: Orderer TLS Cert priv key
   ├── peers
   │   └── org1-peer0
   │       ├── msp
   │       │   ├── admincerts
   │       │   │   └── cert.pem        <--- CERT: User Cert: Admin
   │       │   ├── cacerts
   │       │   │   └── ca-cert.pem     <--- CERT: Root CA
   │       │   ├── config.yaml
   │       │   ├── keystore
   │       │   │   └── {...}_sk        <---  KEY: Peer Cert priv key: peer0
   │       │   ├── signcerts
   │       │   │   └── cert.pem        <--- CERT: Peer Cert: peer0
   │       │   └── tlscacerts
   │       │       └── tlsca-cert.pem  <--- CERT: Root TLS CA Cert
   │       └── tls
   │           ├── tlsca-cert.pem      <--- CERT: Root TLS CA Cert
   │           ├── server.crt          <--- CERT: Peer TLS Cert: peer0
   │           └── server.key          <---  KEY: Peer TLS Cert priv key: peer0
   ├── tlsca
   │   ├── {...}_sk                    <---  KEY: Root TLS CA Cert priv key
   │   └── tlsca-cert.pem              <--- CERT: Root TLS CA Cert
   └── users
       ├── org1-admin
       │   ├── msp
       │   │   ├── admincerts
       │   │   │   └── cert.pem        <--- CERT: User Cert: Admin
       │   │   ├── cacerts
       │   │   │   └── ca-cert.pem     <--- CERT: Root CA
       │   │   ├── keystore
       │   │   │   └── {...}_sk        <---  KEY: User Cert priv key: Admin
       │   │   ├── signcerts
       │   │   │   └── cert.pem        <--- CERT: User Cert: Admin
       │   │   └── tlscacerts
       │   │       └── tlsca-cert.pem  <--- CERT: Root TLS CA Cert
       │   └── tls
       │       ├── tlsca-cert.pem      <--- CERT: Root TLS CA Cert
       │       ├── client.crt          <--- CERT: User TLS Cert: Admin
       │       └── client.key          <---  KEY: User TLS Cert priv key: Admin
       └── org1-user1
           ├── msp
           │   ├── admincerts
           │   │   └── cert.pem        <--- CERT: User Cert: User1
           │   ├── cacerts
           │   │   └── ca-cert.pem     <--- CERT: Root CA
           │   ├── keystore
           │   │   └── {...}_sk        <--- KEY: User Cert priv key: User1
           │   ├── signcerts
           │   │   └── cert.pem        <--- CERT: User Cert: User1
           │   └── tlscacerts
           │       └── tlsca-cert.pem  <--- CERT: Root TLS CA Cert
           └── tls
               ├── tlsca-cert.pem      <--- CERT: Root TLS CA Cert
               ├── client.crt          <--- CERT: User TLS Cert: User1
               └── client.key          <--- KEY: User TLS Cert priv key: User1
</pre>



### First-Network MSP Structure w/ Detail:

<pre style="line-height: 0.7;">
.
├── ordererOrganizations
│   └── example.com
│       ├── ca
│       │   ├── {...}_sk                                    <---  KEY: MIG...OLE -- Root CA priv key
│       │   └── ca.example.com-cert.pem                     <--- CERT: MII.../19 -- Root CA
│       ├── msp
│       │   ├── admincerts
│       │   │   └── Admin@example.com-cert.pem              <--- CERT: MII.../ZS -- User Cert: Admin
│       │   ├── cacerts
│       │   │   └── ca.example.com-cert.pem                 <--- CERT: MII.../19 -- Root CA
│       │   └── tlscacerts
│       │       └── tlsca.example.com-cert.pem              <--- CERT: MII...1E= -- Root TLS CA Cert
│       ├── orderers
│       │   └── orderer.example.com
│       │       ├── msp
│       │       │   ├── admincerts
│       │       │   │   └── Admin@example.com-cert.pem      <--- CERT: MII.../ZS -- User Cert: Admin
│       │       │   ├── cacerts
│       │       │   │   └── ca.example.com-cert.pem         <--- CERT: MII.../19 -- Root CA
│       │       │   ├── keystore
│       │       │   │   └── {...}_sk                        <---  KEY: MIG...R58 -- Orderer Cert priv key
│       │       │   ├── signcerts
│       │       │   │   └── orderer.example.com-cert.pem    <--- CERT: MII...Mm6 -- Orderer Cert
│       │       │   └── tlscacerts
│       │       │       └── tlsca.example.com-cert.pem      <--- CERT: MII...1E= -- Root TLS CA Cert
│       │       └── tls
│       │           ├── ca.crt                              <--- CERT: MII...1E= -- Root TLS CA Cert
│       │           ├── server.crt                          <--- CERT: MII...+r0 -- Orderer TLS Cert
│       │           └── server.key                          <---  KEY: MIG...rVc -- Orderer TLS Cert priv key
│       ├── tlsca
│       │   ├── {...}_sk                                    <---  KEY: MIG...SSj -- Root TLS CA Cert priv key
│       │   └── tlsca.example.com-cert.pem                  <--- CERT: MII...1E= -- Root TLS CA Cert
│       └── users
│           └── Admin@example.com
│               ├── msp
│               │   ├── admincerts
│               │   │   └── Admin@example.com-cert.pem      <--- CERT: MII.../ZS -- User Cert: Admin
│               │   ├── cacerts
│               │   │   └── ca.example.com-cert.pem         <--- CERT: MII.../19 -- Root CA
│               │   ├── keystore
│               │   │   └── {...}_sk                        <---  KEY: MIG...fCD -- User Cert priv key: Admin
│               │   ├── signcerts
│               │   │   └── Admin@example.com-cert.pem      <--- CERT: MII.../ZS -- User Cert: Admin
│               │   └── tlscacerts
│               │       └── tlsca.example.com-cert.pem      <--- CERT: MII...1E= -- Root TLS CA Cert
│               └── tls
│                   ├── ca.crt                              <--- CERT: MII...1E= -- Root TLS CA Cert
│                   ├── client.crt                          <--- CERT: MII...H4= -- User TLS Cert: Admin
│                   └── client.key                          <---  KEY: MIG...5rY -- User TLS Cert priv key: Admin
└── peerOrganizations
    └── org1.example.com
       ├── ca
       │   ├── {...}_sk                                     <---  KEY: MIG...5bQ -- Root CA priv key
       │   └── ca.org1.example.com-cert.pem                 <--- CERT: MII...TOK -- Root CA
       ├── msp
       │   ├── admincerts
       │   │   └── Admin@org1.example.com-cert.pem          <--- CERT: MII.../jA -- User Cert: Admin
       │   ├── cacerts
       │   │   └── ca.org1.example.com-cert.pem             <--- CERT: MII...TOK -- Root CA
       │   ├── config.yaml
       │   └── tlscacerts
       │       └── tlsca.org1.example.com-cert.pem          <--- CERT: MII...w== -- Root TLS CA Cert
       ├── peers
       │   ├── peer0.org1.example.com
       │   │   ├── msp
       │   │   │   ├── admincerts
       │   │   │   │   └── Admin@org1.example.com-cert.pem  <--- CERT: MII.../jA -- User Cert: Admin
       │   │   │   ├── cacerts
       │   │   │   │   └── ca.org1.example.com-cert.pem     <--- CERT: MII...TOK -- Root CA
       │   │   │   ├── config.yaml
       │   │   │   ├── keystore
       │   │   │   │   └── {...}_sk                         <---  KEY: MIG...d4Q -- Peer Cert priv key: peer0
       │   │   │   ├── signcerts
       │   │   │   │   └── peer0.org1.example.com-cert.pem  <--- CERT: MII...wA== -- Peer Cert: peer0
       │   │   │   └── tlscacerts
       │   │   │       └── tlsca.org1.example.com-cert.pem  <--- CERT: MII...w== -- Root TLS CA Cert
       │   │   └── tls
       │   │       ├── ca.crt                               <--- CERT: MII...w== -- Root TLS CA Cert
       │   │       ├── server.crt                           <--- CERT: MII...XA== -- Peer TLS Cert: peer0
       │   │       └── server.key                           <---  KEY: MIG...W+3 -- Peer TLS Cert priv key: peer0
       │   └── peer1.org1.example.com
       │       ├── msp
       │       │   ├── admincerts
       │       │   │   └── Admin@org1.example.com-cert.pem  <--- CERT: MII.../jA -- User Cert: Admin
       │       │   ├── cacerts
       │       │   │   └── ca.org1.example.com-cert.pem     <--- CERT: MII...TOK -- Root CA
       │       │   ├── config.yaml
       │       │   ├── keystore
       │       │   │   └── {...}_sk                         <---  KEY: MIG...xF8 -- Peer Cert priv key: peer1
       │       │   ├── signcerts
       │       │   │   └── peer1.org1.example.com-cert.pem  <--- CERT: MII...bgi -- Peer Cert: peer1
       │       │   └── tlscacerts
       │       │       └── tlsca.org1.example.com-cert.pem  <--- CERT: MII...w== -- Root TLS CA Cert
       │       └── tls
       │           ├── ca.crt                               <--- CERT: MII...w== -- Root TLS CA Cert
       │           ├── server.crt                           <--- CERT: MII...B/w -- Peer TLS Cert: peer1
       │           └── server.key                           <---  KEY: MIG...0b1 -- Peer TLS Cert priv key: peer1
       ├── tlsca
       │   ├── {...}_sk                                     <---  KEY: MIG...gYD -- Root TLS CA Cert priv key
       │   └── tlsca.org1.example.com-cert.pem              <--- CERT: MII...w== -- Root TLS CA Cert
       └── users
           ├── Admin@org1.example.com
           │   ├── msp
           │   │   ├── admincerts
           │   │   │   └── Admin@org1.example.com-cert.pem  <--- CERT: MII.../jA -- User Cert: Admin
           │   │   ├── cacerts
           │   │   │   └── ca.org1.example.com-cert.pem     <--- CERT: MII...TOK -- Root CA
           │   │   ├── keystore
           │   │   │   └── {...}_sk                         <---  KEY: MIG...l4K -- User Cert priv key: Admin
           │   │   ├── signcerts
           │   │   │   └── Admin@org1.example.com-cert.pem  <--- CERT: MII.../jA -- User Cert: Admin
           │   │   └── tlscacerts
           │   │       └── tlsca.org1.example.com-cert.pem  <--- CERT: MII...w== -- Root TLS CA Cert
           │   └── tls
           │       ├── ca.crt                               <--- CERT: MII...w== -- Root TLS CA Cert
           │       ├── client.crt                           <--- CERT: MII...Y07 -- User TLS Cert: Admin
           │       └── client.key                           <---  KEY: MIG...dil -- User TLS Cert priv key: Admin
           └── User1@org1.example.com
               ├── msp
               │   ├── admincerts
               │   │   └── User1@org1.example.com-cert.pem  <--- CERT: MII...P8= -- User Cert: User1
               │   ├── cacerts
               │   │   └── ca.org1.example.com-cert.pem     <--- CERT: MII...TOK -- Root CA
               │   ├── keystore
               │   │   └── {...}_sk                         <---  KEY: MIG...55w -- User Cert priv key: User1
               │   ├── signcerts
               │   │   └── User1@org1.example.com-cert.pem  <--- CERT: MII...P8= -- User Cert: User1
               │   └── tlscacerts
               │       └── tlsca.org1.example.com-cert.pem  <--- CERT: MII...w== -- Root TLS CA Cert
               └── tls
                   ├── ca.crt                               <--- CERT: MII...w== -- Root TLS CA Cert
                   ├── client.crt                           <--- CERT: MII...f0= -- User TLS Cert: User1
                   └── client.key                           <---  KEY: MIG...1fm -- User TLS Cert priv key: User1
</pre>
