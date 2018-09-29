# Outer Rim Trade Network
This network runs on a solo orderer (hosted by one org) and static docker containers (no swarm, etc.)

---
## NOTES
* Most services (containers) also include a `*_auto.sh` file in their directory.  You can use these scripts (change the docker-compose file `command:` section) to more quickly setup the network.  The manual steps are listed below for educational purposes.  Try out the manual process to get a better feel for how the network components interact.

* IF YOU MODIFY THE ORG NAMES, change the commands in this tutorial as needed, and be sure to check the `docker-compose.yaml` and `configtx.yaml` files.

---

### Cryptographic Material: For an overview of the MSP structure, check out the [CRYPTO](../CRYPTO.md) page.

## QUICKSTART: For fewer manual steps, see the [QUICKSTART README](QUICKSTART.md).

## Network Detail: see the generic [orderer_solo](../orderer_solo) example for more notes.

<br>
<br>

# SETUP - DOCKER NETWORK
Start the network separately to ensure the network name is consistent in all secondary docker-compose files.
<br>
<br>**0.1) Start the Docker Network**
>`docker network create outer_rim_trade`

(you can check the running docker networks with `docker network list`)

<br>Move to this network's top directory:
>`cd {repo home}/outer_rim_trade`

<br>
<br>

# HUTT CORP.
## HUTT CORP. CA Service
**1.1) Start the huttcorp CA service**
>`docker-compose -f huttcorp/ca/docker-compose.yaml up -d`

**1.2) Start a Bash session in the huttcorp CA service**
>`docker exec -it huttcorp-ca bash`

NOTE: If you explore the container filesystem, a CA cert and key are created in a `.../fabric-ca-server` sibling directory to the home directory.  This material can be ignored for our purposes.  The CSR detail on this material is default, and we will not use this crypto material for our network.
<br>
<br>

#### The following step occurs inside the huttcorp CA Bash session:
>**1.3) Initialize the CA server**
>>`fabric-ca-server init -b huttcorp-admin-ca:adminpw >>/shared/logs/ca.log 2>&1 &`
>
>The `>>...` redirect will hide the stdout and stderror from your command line.  You will need to open `ca.log` to check for errors.  You can change the "-b" bootstrap option (format: `admin:adminpw`) to whatever admin username / password you want for the CA server admin.
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
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/huttcorp-root-ca-cert.pem`
>
>The Root CA Cert is needed to `enroll` from the CLI.  We will refer to this file in other services (containers) via the `FABRIC_CA_CLIENT_TLS_CERTFILES` environment variable.  You could also hard-code the filename in the CLI config file (fabric-ca-client-config.yaml) in the `tls: certfiles:` section to include the cert as a trusted root certificate.
>
><br>
>
>**1.5) Edit the CA Server Config File**
><br>Edit the "affiliations" section of the config file.  This can also be done manually in the file.  (Note: the below command is formatted differently to ensure extra spaces are captured.  You need to enter this with these extra spaces, or it will not be recognized in the config file)
>><pre>sed -i "/affiliations:/a \\   huttcorp: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml</pre>
>
><br>(Optional) If you have minor changes you would like to make to the `fabric-ca-server-config.yaml` file, you can make those changes now.  If you would like to customize the entire config file and not rely on any default generation process during `init`, you can save a customized config file in the `FABRIC_CA_SERVER_HOME` directory before initialization and fabric-ca-server will use the custom file rather than generate a default.  For this example, we will use the default file and override some settings via the environmental variables.
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

## HUTT CORP. CLI (tools) Service
**1.7) Start the huttcorp CLI (tools) service**
>`docker-compose -f huttcorp/cli/docker-compose.yaml up -d`

<br>

**1.8) Start a Bash session in the huttcorp CLI service**
>`docker exec -it huttcorp-cli bash`

#### The following steps occur inside the huttcorp CLI Bash session:
>If you exit and re-enter the Bash session, you will need to reset the environment variables.  Example: `export FABRIC_CFG_PATH=/etc/hyperledger/fabric`
>
><br>
>
>**1.9) Enroll the CA administrator**
><br>First, create the needed msp directory and set the environment variables needed.  The `$FABRIC_CFG_PATH` was set when the container was started (default: `/etc/hyperledger/fabric`)
>>`export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/huttcorp-root-ca-cert.pem`
><br>`mkdir -p $FABRIC_CFG_PATH/orgs/huttcorp/ca/huttcorp-admin-ca`
><br>`export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/huttcorp/ca/huttcorp-admin-ca`
>
><br>Enroll the CA admin:
>>`fabric-ca-client enroll -d -u https://huttcorp-admin-ca:adminpw@huttcorp-ca:7054`
>
><br>An MSP directory should have been created in the `FABRIC_CA_CLIENT_HOME` directory (currently `$FABRIC_CFG_PATH/orgs/huttcorp/ca/huttcorp-admin-ca`), with a default client config file (if not preexisting).  The `msp/cacerts/huttcorp-ca-7054.pem` is the same certificate as the ca-cert.pem (renamed huttcorp-root-ca-cert.pem) we created in the CA and passed to the `/shared` directory to be used in the CLI config file.
>
><pre style="line-height: 1.3;">
>...orgs/huttcorp/ca/huttcorp-admin-ca
>└── msp
>    ├── cacerts
>    │   └── huttcorp-ca-7054.pem   <--- matches Root CA Cert ("huttcorp-root-ca-cert.pem")
>    ├── keystore
>    │   ├── {...}_sk
>    ├── signcerts
>    │   └── cert.pem
>    └── user
></pre>
>
><br>The SDK uses different naming rules, so duplicate and rename the signcerts file:
>
>For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
>>`cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin-ca@huttcorp-cert.pem`
>
>For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
>>`cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/huttcorp-admin-ca@huttcorpMSP-cert.pem`
>
><br>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**1.10) Register the org administrator**
><br>The admin identity has the "admin" attribute which is added to ECert by default.  The other attributes are needed for this example chaincode settings.  Register the admin:
>>`fabric-ca-client register -d --id.name huttcorp-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert"`
>
><br>
>
>**1.11) Register the orderer profile**
>>`fabric-ca-client register -d --id.name huttcorp-orderer --id.secret ordererpw --id.type orderer`
>
><br>
>
>**1.12) Register the peer profile**
>>`fabric-ca-client register -d --id.name huttcorp-peer0 --id.secret peerpw --id.type peer`
>
><br>
>
>**1.13) Generate client TLS cert and key pair for the peer commands**
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://huttcorp-peer0:peerpw@huttcorp-ca:7054 -M /tmp/tls --csr.hosts huttcorp-peer0`
>
>Copy the TLS key and cert to the common tls dir
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/huttcorp/tls/huttcorp-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/huttcorp/tls/huttcorp-peer0-cli-client.key`
>
>
><br>
>
>**1.14) Create the MSP directory tree**
><br>Get the root ca cert again and auto-create the huttcorp MSP tree
>>`fabric-ca-client getcacert -d -u https://huttcorp-ca:7054 -M $FABRIC_CFG_PATH/orgs/huttcorp/msp`
>
><pre style="line-height: 1.3;">
>...orgs/huttcorp
>└── msp
>    ├── cacerts
>    │   └── huttcorp-ca-7054.pem   <--- from "fabric-ca-client getcacert"
>    ├── keystore
>    ├── signcerts
>    └── user
></pre>
>
>**1.15) Copy the tlscacert to the admin-ca msp tree**
>>`/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/huttcorp/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/huttcorp/msp`
>
><br>
>
>**1.16) Enroll the ORG ADMIN and populate the admincerts directory**
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
>**1.17) Create the Channel Artifacts**
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
>**1.18) (OPTIONAL) Register a user**
><br>Note: You will get an Authorization error if you attempt to register without a register-capable Identity (like the org ca admin)
>>`fabric-ca-client register -d --id.name huttcorp-bFortuna --id.secret userpw`
>
><br>
>
>**1.19) Register a default user to initialize the SDK**
>>`fabric-ca-client register -d --id.name huttcorp-sdk --id.secret sdkpw`
>><br>`. $FABRIC_CFG_PATH/setup/login.sh -u huttcorp-sdk -p sdkpw -c /shared/huttcorp-root-ca-cert.pem`
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## HUTT CORP. ORDERER
**1.20) Start the huttcorp ORDERER service**
>`docker-compose -f huttcorp/orderer/docker-compose.yaml up -d`

<br>

**1.21) Start a Bash session in the huttcorp ORDERER service**
>`docker exec -it huttcorp-orderer bash`

#### The following step occurs inside the huttcorp ORDERER Bash session:
>The env vars should be set by the docker compose file, including: `$FABRIC_CA_CLIENT_HOME`
>
><br>
>
>**1.22) Enroll profile & fill MSP tree**
>
>Enroll the orderer profile to get the orderer's enrollment certificate (default profile):
>>`fabric-ca-client enroll -d -u https://huttcorp-orderer:ordererpw@huttcorp-ca:7054 -M $FABRIC_CA_CLIENT_HOME/msp`
>
>Copy the tlscacert to the orderer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $ORDERER_GENERAL_LOCALMSPDIR/cacerts/* -m $ORDERER_GENERAL_LOCALMSPDIR`
>
>Copy the admincert to the orderer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/huttcorp-admin@huttcorp-cert.pem -m $ORDERER_GENERAL_LOCALMSPDIR`
>
><br>
>
>**1.23) Enroll the orderer to get TLS & Certs**
>
>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://huttcorp-orderer:ordererpw@huttcorp-ca:7054 -M /tmp/tls --csr.hosts huttcorp-orderer`
>
>
>Copy the TLS key and cert to the tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $ORDERER_GENERAL_TLS_CERTIFICATE -k $ORDERER_GENERAL_TLS_PRIVATEKEY`
>
><br>The msp directory tree should now look like the ORDERER tree shown on the [CRYPTO](../CRYPTO.md) page.
>
><br>
>
>**1.24) Start the orderer**
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

## HUTT CORP. COUCHDB
**1.25) Start the huttcorp COUCHDB service**
>`docker-compose -f huttcorp/couchdb/docker-compose.yaml up -d`

<br><br>The default hyperledger couchdb container does not need customizing other than the environment variables in the docker compose file.

<br>
<br>

## HUTT CORP. ANCHOR PEER
**1.27) Start the huttcorp PEER0 service**
>`docker-compose -f huttcorp/peer0/docker-compose.yaml up -d`

<br>

**1.28) Start a Bash session in the huttcorp PEER0 service**
>`docker exec -it huttcorp-peer0 bash`

#### The following step occurs inside the huttcorp PEER0 Bash session:
>The env vars should be set, including: `$CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**1.29) Enroll profile & fill MSP tree**
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://huttcorp-peer0:peerpw@huttcorp-ca:7054 -M $CORE_PEER_MSPCONFIGPATH`
>
>Copy the tlscacert to the peer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH`
>
>Copy the admincert to the peer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/huttcorp-admin@huttcorp-cert.pem -m $CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**1.30) Enroll the peer to get TLS & Certs**
><br>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://huttcorp-peer0:peerpw@huttcorp-ca:7054 -M /tmp/tls --csr.hosts huttcorp-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE`
>
><br>The msp directory tree should now look like the PEER tree shown on the [CRYPTO](../CRYPTO.md) page.
>
><br>
>
>**1.31) Start the peer**
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
**1.32) Start the huttcorp CLI (tools) service**
>`docker exec -it huttcorp-cli bash`

#### The following steps occur inside the huttcorp CLI Bash session:
>Reload the environment variables and the admin profile
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. /etc/hyperledger/fabric/setup/login-admin.sh`
>
><br>
>
>**1.33) Create the Channel**
>>`peer channel create --logging-level=DEBUG -c spicechannel -f $FABRIC_CFG_PATH/channel.tx $ORDERER_CONN_ARGS`
>
><br>
>
>**1.34) Join the Channel**
><br>You might need to retry to join the channel several times
>>`peer channel join -b spicechannel.block`
>
><br>
>
>**1.35) Update the Channel with the new Anchor Peer**
>>`peer channel update -c spicechannel -f $FABRIC_CFG_PATH/huttcorp-anchors.tx $ORDERER_CONN_ARGS`
>
><br>
>
>**1.36) Install the Wallet Chaincode on the new Anchor Peer**
>>`peer chaincode install -n ccWallet -p chaincode/wallet -v 1.0`
>
><br>
>
>**1.37) Instantiate the Wallet Chaincode on the new Anchor Peer**
>>`peer chaincode instantiate -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.0`
>
><br>
>
>**1.38) Install the User Chaincode on the new Anchor Peer**
>>`peer chaincode install -n ccUser -p chaincode/user -v 1.0`
>
><br>
>
>**1.39) Instantiate the User Chaincode on the new Anchor Peer**
>>`peer chaincode instantiate -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member')" $ORDERER_CONN_ARGS -v 1.0`
>
><br>
>
>**1.40) Test the Chaincode**
><br>Create a new Wallet ledger entry (note that this will not create a User ledger entry)
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["create","Jabba"]}'`
>
>Deposit credits into the created Wallet
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["deposit","Jabba","1000000"]}'`
>
>Wait a few seconds to ensure that the ledger was updated, and then query the ledger to check the Wallet balance
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","Jabba"]}'`
>
>If the new Wallet balance was correctly updated, your network is complete with Hutt Corp.!
>
><br>
>
><br>
>
>**1.41) Start the Client App**
>
>Packages need to be imported before running the Client App
>>yes | go get -u github.com/hyperledger/fabric-sdk-go
><br>yes | go get -u github.com/gin-contrib/sessions
><br>yes | go get -u github.com/gin-contrib/static
><br>yes | go get -u github.com/gin-gonic/gin
><br>yes | go get -u github.com/cloudflare/cfssl/cmd/cfssl
><br>yes | go get -u github.com/golang/mock/gomock
><br>yes | go get -u github.com/mitchellh/mapstructure
><br>yes | go get -u github.com/pkg/errors
><br>yes | go get -u github.com/spf13/cast
><br>yes | go get -u github.com/spf13/viper
><br>yes | go get -u github.com/stretchr/testify/assert
><br>yes | go get -u golang.org/x/crypto/ocsp
><br>yes | go get -u golang.org/x/crypto/sha3
><br>yes | go get -u golang.org/x/net/context
><br>yes | go get -u google.golang.org/grpc
><br>yes | go get -u gopkg.in/go-playground/validator.v8
><br>yes | go get -u gopkg.in/yaml.v2
><br>yes | apt-get update
><br>yes | apt-get install iputils-ping
>
>The client app uses local imports (not recommended for most Go packages), so move to the client directory before running the app
>>`cd /etc/hyperledger/fabric/setup/client`
>
>Set up and serve the Hutt Corp. client app on a local port (compilation might take a minute) 
>>`go run main.go`
>
>If successful, the terminal should show the app hosted a listening on a local port
>```
>[GIN-debug] GET    /session                  --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Session-fm (5 handlers)
>[GIN-debug] POST   /login                    --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Login-fm (5 handlers)
>[GIN-debug] GET    /logout                   --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Logout-fm (5 handlers)
>[GIN-debug] GET    /api/query                --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Query-fm (6 handlers)
>[GIN-debug] POST   /api/deposit              --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Deposit-fm (6 handlers)
>[GIN-debug] POST   /api/transfer             --> _/etc/hyperledger/fabric/setup/client/app.(*Application).Transfer-fm (6 handlers)
>[GIN-debug] Listening and serving HTTP on :3000
>```

1.41.1) Open a browser and load http://localhost:3000 to view the app
<br>NOTE: If you have previously set up the network and app, be sure to log out - saved session data will cause the appearance of being logged in without having created the account.
<br><br>![app login](./readme_media/org1_app_login.png)

1.41.2) Enter a username and password to log in or create a new account
<br>Note: the login process might take a few seconds if this is a new account
<br><br>![app create account](./readme_media/org1_app_new_account.png)

1.41.3) Deposit into the account
<br>In this example, Han just got a prepayment of 2,000 credits.  Enter 1,000 twice since the maximum single deposit amount is 1,000.
<br><br>![app deposit](./readme_media/org1_app_deposit.png)

1.41.4) Transfer to another account
<br>In this example, Han owes Jabba 10,000 credits with 20% interest.  Han decides to go ahead and transfer the 2,000 credits to appease Jabba.
<br><br>![app transfer](./readme_media/org1_app_transfer.png)
<br><br>![app transfer confirmation](./readme_media/org1_app_transfer2.png)

<br>You can view the CouchDB World State entries by going to http://localhost:5984/_utils
<br>NOTE: This port was exposed in the "huttcorp-couchdb" `docker-compose.yaml` file.  Due to security concerns, the port should not be exposed in production.
<br><br>You will need to log in using the username / password used in the couchdb container.  The default is:
<br>username: huttcorp-couchdb
<br>password: couchdb
<br><br>![couchdb wallet](./readme_media/org1_couchdb_wallet.png)
<br>Notice that although the Wallet table shows both accounts, the User table does not include an entry for the Wallet we created via the CLI ("Jabba" in this example).  Because the CLI does not utilize the client app w/ SDK, it directly accesses the chaincode and bypasses any additional processes in the client app (in this case, automatically creating a User account for each Wallet account).
<br><br>![couchdb user](./readme_media/org1_couchdb_user.png)

<br>You can leave the Client App running for now.

<br>
<br>
<br>


# CLOUD CITY INC.
### Adding additional orgs at any time follows this same process
<br>Open a new terminal window (so later we can run both org client apps at the same time)

## CLOUD CITY INC. CA SERVICE
**2.1) Start the cloudcityinc CA service**
>`docker-compose -f cloudcityinc/ca/docker-compose.yaml up -d`

<br>

**2.2) Start a Bash session in the cloudcityinc CA service**
>`docker exec -it cloudcityinc-ca bash`

#### The following step occurs inside the cloudcityinc CA Bash session:
>**2.3) Initialize the CA server**
>>`fabric-ca-server init -b cloudcityinc-admin-ca:adminpw >>/shared/logs/ca.log 2>&1 &`
>
><br>
>
>**2.4) Copy the crypto material**
><br>Copy the Root CA Cert ONLY to the shared folder for production use.
>>`cp $FABRIC_CA_SERVER_HOME/ca-cert.pem /shared/cloudcityinc-root-ca-cert.pem`
>
><br>
>
>**2.5) Edit the CA Server Config File**
><br>Edit the "affiliations" section of the config file.  This can also be done manually in the file.  (Note: the below command is formatted differently to ensure extra spaces are captured.  You need to enter this with these extra spaces, or it will not be recognized in the config file)
>><pre>sed -i "/affiliations:/a \\   cloudcityinc: []" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml</pre>
>
>**2.6) Start the CA Server**
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

## CLOUD CITY INC. CLI (tools) Service
**2.7) Start the cloudcityinc CLI (tools) service**
>`docker-compose -f cloudcityinc/cli/docker-compose.yaml up -d`

<br>

**2.8) Start a Bash session in the cloudcityinc CLI service**
>`docker exec -it cloudcityinc-cli bash`

#### The following steps occur inside the cloudcityinc CLI Bash session:
>If you exit and re-enter the Bash session, you might need to reset the environment variables.  Example: `export FABRIC_CFG_PATH=/etc/hyperledger/fabric`
>
><br>
>
>**2.9) Enroll the CA administrator**
><br>First, create the needed msp directory and set the environment variables needed.  The `$FABRIC_CFG_PATH` was set when the container was started (default: `/etc/hyperledger/fabric`)
>>`export FABRIC_CA_CLIENT_TLS_CERTFILES=/shared/cloudcityinc-root-ca-cert.pem`
><br>`mkdir -p $FABRIC_CFG_PATH/orgs/cloudcityinc/ca/cloudcityinc-admin-ca`
><br>`export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/orgs/cloudcityinc/ca/cloudcityinc-admin-ca`
>
><br>Enroll the CA admin:
>>`fabric-ca-client enroll -d -u https://cloudcityinc-admin-ca:adminpw@cloudcityinc-ca:7054`
>
><br>The SDK uses different naming rules, so duplicate and rename the signcerts file:
>
>For filekeyvaluestore (github.com/hyperledger/fabric-sdk-go/pkg/msp/filecertstore.go):
>>`cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/cloudcityinc-admin-ca@cloudcityinc-cert.pem`
>
>For certfileuserstore (github.com/hyperledger/fabric-sdk-go/pkg/msp/certfileuserstore.go):
>>`cp $FABRIC_CA_CLIENT_HOME/msp/signcerts/cert.pem $FABRIC_CA_CLIENT_HOME/msp/signcerts/cloudcityinc-admin-ca@cloudcityincMSP-cert.pem`
>
><br>
><br>
>
>### **Registration** of orderer(s), peer(s), and user(s)
>Registration adds an entry into the `fabric-ca-server.db` or LDAP
>
>**2.9) Register the org administrator**
><br>The admin identity has the "admin" attribute which is added to ECert by default.  The other attributes are needed for this example chaincode settings.  Register the admin:
>>`fabric-ca-client register -d --id.name cloudcityinc-admin --id.secret adminpw --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert"`
>
><br>
>
>**2.10) Register the peer profile**
>>`fabric-ca-client register -d --id.name cloudcityinc-peer0 --id.secret peerpw --id.type peer`
>
><br>
>
>**2.13) Generate client TLS cert and key pair for the peer commands**
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M /tmp/tls --csr.hosts cloudcityinc-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $FABRIC_CFG_PATH/orgs/cloudcityinc/tls/cloudcityinc-peer0-cli-client.crt -k $FABRIC_CFG_PATH/orgs/cloudcityinc/tls/cloudcityinc-peer0-cli-client.key`
>
><br>
>
>**2.14) Create the MSP directory tree**
><br>Get the root ca cert again and auto-create the Cloud City Inc. MSP tree
>>`fabric-ca-client getcacert -d -u https://cloudcityinc-ca:7054 -M $FABRIC_CFG_PATH/orgs/cloudcityinc/msp`
>
><br>
>
>**2.15) Copy the tlscacert to the admin-ca msp tree**
>>`/shared/utils/msp_add_tlscacert.sh -c $FABRIC_CFG_PATH/orgs/cloudcityinc/msp/cacerts/* -m $FABRIC_CFG_PATH/orgs/cloudcityinc/msp`
>
><br>
>
>**2.16) Enroll the ORG ADMIN and populate the admincerts directory**
><br>NOTE: MUST RUN `login-admin.sh` with ". /" to capture env vars
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. $FABRIC_CFG_PATH/setup/login-admin.sh`
>
><br>
>
>**2.17) Use the configtxgen tool to generate the org info JSON to join the channel**
><br>Move the configtx.yaml file to the FABRIC_CFG_PATH directory (see docker compose env vars)
>>`cp /etc/hyperledger/fabric/setup/configtx.yaml /etc/hyperledger/fabric/configtx.yaml`
>
>Generate the Org info using the configtxgen tool for joining the existing channel
>>`configtxgen -channelID spicechannel -printOrg cloudcityinc > cloudcityinc.json`
>
>pass cloudcityinc.json to common folder for use by authorizing org(s)
>>`cp cloudcityinc.json /shared/cloudcityinc.json`
><br>
>
><br>
>
>**2.11) Register a default user to initialize the SDK**
>>`fabric-ca-client register -d --id.name cloudcityinc-sdk --id.secret sdkpw`
>><br>`. $FABRIC_CFG_PATH/setup/login.sh -u cloudcityinc-sdk -p sdkpw -c /shared/cloudcityinc-root-ca-cert.pem`
>
><br>
>
>**2.12) (OPTIONAL) Register a user**
>>`fabric-ca-client register -d --id.name cloudcityinc-lobot --id.secret userpw`
>
><br>
>
>End the Bash session with `exit`

<br>
<br>

## MANUAL TRANSFER
**2.18) MANUAL TRANSFER Cloud City Inc. -> Hutt Corp.**
- Copy created `.json` file to huttcorp `/shared` directory

<br>

**2.19) MANUAL TRANSFER Hutt Corp. -> Cloud City Inc.**
- Copy `huttcorp-root-ca-cert.pem` to cloudcityinc `/shared` directory

<br>
<br>

## CLOUD CITY INC. COUCHDB
**2.20) Start the cloudcityinc COUCHDB service**
>`docker-compose -f cloudcityinc/couchdb/docker-compose.yaml up -d`

<br>The default hyperledger couchdb container does not need customizing other than the environment variables in the docker compose file.

<br>
<br>

## CLOUD CITY INC. ANCHOR PEER
**2.21) Start the cloudcityinc PEER0 service**
>`docker-compose -f cloudcityinc/peer0/docker-compose.yaml up -d`

<br>

**2.22) Start a Bash session in the cloudcityinc PEER0 service**
>`docker exec -it cloudcityinc-peer0 bash`

#### The following step occurs inside the cloudcityinc PEER0 Bash session:
>The env vars should be set, including: `$CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**2.23) Enroll profile & fill MSP tree**
>
>Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
>>`fabric-ca-client enroll -d -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M $CORE_PEER_MSPCONFIGPATH`
>
>Copy the tlscacert to the peer msp tree
>>`/shared/utils/msp_add_tlscacert.sh -c $CORE_PEER_MSPCONFIGPATH/cacerts/* -m $CORE_PEER_MSPCONFIGPATH`
>
>Copy the admincert to the peer msp tree
>>`/shared/utils/msp_add_admincert.sh -c /shared/cloudcityinc-admin@cloudcityinc-cert.pem -m $CORE_PEER_MSPCONFIGPATH`
>
><br>
>
>**2.24) Enroll the orderer to get TLS & Certs**
><br>Use the `--enrollment.profile` `tls` option to receive the TLS key & cert
>>`fabric-ca-client enroll -d --enrollment.profile tls -u https://cloudcityinc-peer0:peerpw@cloudcityinc-ca:7054 -M /tmp/tls --csr.hosts cloudcityinc-peer0`
>
>Copy the TLS key and cert to the local tls directory
>>`/shared/utils/tls_add_crtkey.sh -d -p /tmp/tls -c $CORE_PEER_TLS_CERT_FILE -k $CORE_PEER_TLS_KEY_FILE`
>
><br>
>
>**2.25) Start the peer**
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

## HUTT CORP. CLI - UPGRADE CHAINCODE
**2.26) Start a Bash session in the huttcorp CLI service**
<br>Switch back to the huttcorp terminal window (or `docker exec -it huttcorp-cli bash` into the huttcorp CLI if needed).  You might need to `Ctrl+c` to stop the client app from listening on the port).

#### The following step occurs inside the huttcorp CLI Bash session:
>**2.27) Install jq (command-line JSON processor)**
>>`apt-get -y update && apt-get -y install jq`
>
><br>
>
>**2.28) Fetch the config block for the channel**
>>`peer channel fetch config config_block.pb -c spicechannel $ORDERER_CONN_ARGS`
>
>Convert it to json (output to `config.json`)
>>`configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json`
>
><br>
>
>**2.29) Create Config Update Envelope**
><br>Modify the configuration to append Cloud City Inc.
>>`jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"cloudcityinc":.[1]}}}}}' config.json /shared/cloudcityinc.json > modified_config.json`
>
>Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to update_in_envelope.pb
>>`configtxlator proto_encode --input config.json --type common.Config >original_config.pb`
<br>`configtxlator proto_encode --input modified_config.json --type common.Config >modified_config.pb`
<br>`configtxlator compute_update --channel_id spicechannel --original original_config.pb --updated modified_config.pb >config_update.pb`
<br>`configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json`
<br>`echo '{"payload":{"header":{"channel_header":{"channel_id":"spicechannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json`
<br>`configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"update_in_envelope.pb"`
>
><br>
>
>**2.30) Sign the Update Envelope**
>>`peer channel signconfigtx -f update_in_envelope.pb`
>
>Copy the envelope to the common directory and pass to other authorizing admins (if needed)
>>`cp update_in_envelope.pb /shared/update_in_envelope.pb`
>
><br>
>
>**2.31) Update Channel**
><br>After ALL needed admins have signed the update envelope, update the channel
>>`peer channel update -f update_in_envelope.pb -c spicechannel $ORDERER_CONN_ARGS`
>
><br>
>
>**2.32) Install Wallet Chaincode**
><br>Be sure to iterate the chaincode version before installation
>>`peer chaincode install -n ccWallet -p chaincode/wallet -v 2.0`
>
><br>
>
>**2.33) Upgrade Wallet Chaincode**
><br>NOTES:
>- Be sure to use the same chaincode version used on the install
>- Use ".member" NOT ".peer" - a later update will use NodeOUs to enable use of ".peer", ".client", etc.
>
>>`peer chaincode upgrade -C spicechannel -n ccWallet -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member','cloudcityincMSP.member')" $ORDERER_CONN_ARGS -v 2.0`
>
><br>
>
>**2.32) Install User Chaincode**
><br>Be sure to iterate the chaincode version before installation
>>`peer chaincode install -n ccUser -p chaincode/user -v 2.0`
>
><br>
>
>**2.33) Upgrade User Chaincode**
><br>NOTES:
>- Be sure to use the same chaincode version used on the install
>- Use ".member" NOT ".peer" - a later update will use NodeOUs to enable use of ".peer", ".client", etc.
>
>>`peer chaincode upgrade -C spicechannel -n ccUser -c '{"Args":["init",""]}' -P "OR('huttcorpMSP.member','cloudcityincMSP.member')" $ORDERER_CONN_ARGS -v 2.0`
>
><br>
>
>**2.34) Test Chaincode**
><br>First run a query to check the current ledger value
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","Jabba"]}'`
>
>The terminal should show success in querying a sample entry. e.g.:
>```
>Chaincode invoke successful. result: status:200 payload:"[{\"balance\":1002000,\"docType\":\"wallet\",\"owner\":\"Jabba\",\"status\":\"active\"}]"
>```
>
><br>
>
>**2.35) Start Client App**
>Move back to the client app directory and restart the client app service
>>`cd /etc/hyperledger/fabric/setup/client`
>
>>`go run main.go`

<br>
<br>

## CLOUD CITY INC. CLI - INSTALL CHAINCODE
<br>Switch back to the Cloud City Inc. terminal window

**2.36) Start a Bash session in the cloudcityinc CLI service**
>`docker exec -it cloudcityinc-cli bash`

#### The following step occurs inside the cloudcityinc CLI Bash session:
>Reset the env vars & profile:
>>`source /etc/hyperledger/fabric/setup/.env`
<br>`. /etc/hyperledger/fabric/setup/login-admin.sh`
>
><br>
>
>**2.37) Fetch the config block for the channel**
>>`peer channel fetch 0 spicechannel.block -c spicechannel $ORDERER_CONN_ARGS`
>
><br>
>
>**2.38) Join the channel**
>>`peer channel join -b spicechannel.block`
>
><br>
>
>**2.39) Install Wallet Chaincode**
><br>Be sure to match the chaincode version with the other org chaincode install
>>`peer chaincode install -n ccWallet -p chaincode/wallet -v 2.0`
>
><br>
>
>**2.40) Install User Chaincode**
><br>Be sure to match the chaincode version with the other org chaincode install
>>`peer chaincode install -n ccUser -p chaincode/user -v 2.0`
>
><br>
>
>**2.41) Test Chaincode**
><br>First run a query to check the current ledger value
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["create","CloudCity"]}'`
>
>Run an invoke to change the value
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["deposit","CloudCity","10000000"]}'`
>
>Wait a few seconds to ensure the ledger is updated, then check the value to ensure it changed
>>`peer chaincode invoke -C spicechannel -n ccWallet $ORDERER_CONN_ARGS -c '{"Args":["query","CloudCity"]}'`
>
>If the new Wallet balance was correctly updated, your network is complete with Hutt Corp.!

<br>

<br>2.41.1) View the Cloud City Inc. CouchDB World State entries by going to http://localhost:6984/_utils
<br>NOTE: This port was exposed in the "cloudcityinc-couchdb" `docker-compose.yaml` file.  Due to security concerns, the port should not be exposed in production.
<br><br>You will need to log in using the username / password used in the couchdb container.  The default is:
<br>username: cloudcityinc-couchdb
<br>password: couchdb
<br><br>You will notice that not only was the Wallet chaincode `create` command successful in creating the example account ("CloudCity" in this case), but the cloudcityinc peer already recreated the existing blockchain data in the World State database
<br><br>![couchdb wallet](./readme_media/org2_couchdb_wallet.png)

<br>

**2.42) CLOUD CITY INC. CLIENT APP**
#### The following step occurs inside the cloudcityinc CLI Bash session:
>Packages need to be imported before running the Client App
>>yes | go get -u github.com/hyperledger/fabric-sdk-go
><br>yes | go get -u github.com/gin-contrib/sessions
><br>yes | go get -u github.com/gin-contrib/static
><br>yes | go get -u github.com/gin-gonic/gin
><br>yes | go get -u github.com/cloudflare/cfssl/cmd/cfssl
><br>yes | go get -u github.com/golang/mock/gomock
><br>yes | go get -u github.com/mitchellh/mapstructure
><br>yes | go get -u github.com/pkg/errors
><br>yes | go get -u github.com/spf13/cast
><br>yes | go get -u github.com/spf13/viper
><br>yes | go get -u github.com/stretchr/testify/assert
><br>yes | go get -u golang.org/x/crypto/ocsp
><br>yes | go get -u golang.org/x/crypto/sha3
><br>yes | go get -u golang.org/x/net/context
><br>yes | go get -u google.golang.org/grpc
><br>yes | go get -u gopkg.in/go-playground/validator.v8
><br>yes | go get -u gopkg.in/yaml.v2
><br>yes | apt-get update
><br>yes | apt-get install iputils-ping
>
>2.42.1) Move to the client app directory and start the client app service (on :3001 port this time)
>>`cd /etc/hyperledger/fabric/setup/client`
>
>>`go run main.go`

2.42.2) Open a new browser session (such as a private session) and load http://localhost:3001 to view the app

2.42.3) Log into the Cloud City Inc. client app
<br>NOTE: This example app does not restrict access to a client app by organization, but new accounts created via the client app will assign the client app's organization to that new User (for example, creating a new account via the http://localhost:3001 app will create a new User for cloudcityinc)

<br>You can see Cloud City Inc.'s World State data includes all ledger data.
<br><br>NOTE: Sometimes creating a new account takes up to a minute to register, enroll, and prepare the client app
<br><br>![app cloudcityinc data](./readme_media/org2_app_new_account.png)

<br>
<br>

## FINISHED
That's it!  Both orgs are on the network & channel, using the same chaincode, and both client apps are runnning.  Be on the lookout for updates to this repo - advanced features will be added soon!

<br>

### OPTIONAL:

WARNING: THE FOLLOWING COMMANDS WILL REMOVE ALL DOCKER CONTAINERS ON YOUR MACHINE (not just Hyperledger services) - USE WITH CAUTION

You can shut down the network with:
>`{repo home}/network_down.sh`

Or, for automatic cleaning of script-created files, try:
>`yes | {repo home}/network_down.sh delete`