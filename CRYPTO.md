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
    ├── anchors.tx                   <--- Transaction file for this org's anchor peer
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
