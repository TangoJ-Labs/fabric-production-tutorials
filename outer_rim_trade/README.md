# Outer Rim Trade Network

This example does not have a long-form tutorial, so if you're still learning about Hyperledger Fabric, please try the [manual process](../orderer_solo) at least once - it's a great way to learn the network components and understand how they interact.  Watch the output and skim the log files for even more detail.

<br>

NOTES:
- Be sure to check for errors in the logs (in the `/shared` directories) after each container startup.

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

# HUTT CORP. SETUP & CLIENT APP
**1.1) huttcorp CA start**
<br>Start the huttcorp CA and register the CA ADMIN
<br>The CA (Certificate Authority) will issue Identity and TLS certificates to users and nodes
>`docker-compose -f huttcorp/ca/docker-compose.yaml up -d`

<br>

**1.2) huttcorp CLI start**
<br>Start the huttcorp CLI (command line interface) Admin Portal and register users and nodes
>`docker-compose -f huttcorp/cli/docker-compose.yaml up -d`

<br>

**1.3) huttcorp orderer start**
>`docker-compose -f huttcorp/orderer/docker-compose.yaml up -d`

<br>

**1.4) huttcorp couchdb start**
<br>When using a custom World State database (not the default LevelDB), it must be started before the peer node
>`docker-compose -f huttcorp/couchdb/docker-compose.yaml up -d`

<br>

**1.5) huttcorp peer0 start**
>`docker-compose -f huttcorp/peer0/docker-compose.yaml up -d`

<br>

**1.6) huttcorp chaincode start**

Set up the huttcorp chaincodes and test from inside the huttcorp CLI
>`docker exec -it huttcorp-cli bash`

#### The following step occurs inside the huttcorp CLI Bash session:
>Update the channel and upgrade the chaincode (this will take a few minutes):
>>`. /etc/hyperledger/fabric/setup/cc_commands.sh`
>
>If successful, in the terminal you should output a response with a payload containing the queried account's balance similar to:
>```
>Chaincode invoke successful. result: status:200 payload:"[{\"balance\":1000000,\"docType\":\"wallet\",\"owner\":\"Jabba\",\"status\":\"active\"}]"
>```
>
><br>
>
>**1.7) huttcorp client app**
>
>The client app uses local imports (not recommended for most Go packages), so move to the client directory before running the app
>>`cd /etc/hyperledger/fabric/setup/client`
>
>Set up and serve the huttcorp client app on a local port (compilation might take a minute) 
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

1.7.1) Open a browser and load http://localhost:3000 to view the app
<br>NOTE: If you have previously set up the network and app, be sure to log out - saved session data will cause the appearance of being logged in without having created the account.
<br><br>![app login](./readme_media/org1_app_login.png)

1.7.2) Enter a username and password to log in or create a new account
<br>Note: the login process might take a few seconds if this is a new account
<br><br>![app create account](./readme_media/org1_app_new_account.png)

1.7.3) Deposit into the account
<br>In this example, Han just got a prepayment of 2,000 credits.  Enter 1,000 twice since the maximum single deposit amount is 1,000.
<br><br>![app deposit](./readme_media/org1_app_deposit.png)

1.7.4) Transfer to another account
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

# CLOUD CITY INC. SETUP (& CLIENT APP), CHANNEL JOIN, & UPGRADE CHAINCODES
**2.0) cloudcityinc prep**
<br>Open a new terminal window (so later we can run both org client apps at the same time)

**2.1) cloudcityinc CA start**
<br>Set up the cloudcityinc CA and register the CA ADMIN
>`docker-compose -f cloudcityinc/ca/docker-compose.yaml up -d`

<br>

**2.2) cloudcityinc CLI start**
>`docker-compose -f cloudcityinc/cli/docker-compose.yaml up -d`

The cloudcityinc CLI startup script should have created the needed artifacts (MSP tree):
-  Enrolled the CA ADMIN
-  Registered the ORG ADMIN & PEER
-  Got CA CERT and completed MSP tree
-  Generated org info .json with configtxgen (and copied to shared dir)

<br>

**2.3) MANUAL TRANSFER Cloud City Inc. -> Hutt Corp.**
- Copy created `.json` file to huttcorp `/shared` directory

**2.4) MANUAL TRANSFER Hutt Corp. -> Cloud City Inc.**
- Copy `huttcorp-root-ca-cert.pem` to cloudcityinc `/shared` directory

<br>

**2.5) cloudcityinc couchdb start**
>`docker-compose -f cloudcityinc/couchdb/docker-compose.yaml up -d`

<br>

**2.6) cloudcityinc peer0 start**
>`docker-compose -f cloudcityinc/peer0/docker-compose.yaml up -d`

<br>

**2.7) huttcorp CLI**
<br>Switch back to the huttcorp terminal window (or `docker exec -it huttcorp-cli bash` into the huttcorp CLI if needed).  You might need to `Ctrl+c` to stop the client app from listening on the port).

#### The following steps occur inside the huttcorp CLI Bash session:
>2.7.1) Move to the root directory, otherwise temporary files will clutter the client app directory
>>`cd /`
>
>2.7.2) Update the channel and upgrade the chaincodes (this may take a few minutes)
>>`. /etc/hyperledger/fabric/setup/add_org/add_org_upgrade_cc.sh`
>
>2.7.3) The terminal should show success in querying a sample entry. e.g.:
>```
>Chaincode invoke successful. result: status:200 payload:"[{\"balance\":1002000,\"docType\":\"wallet\",\"owner\":\"Jabba\",\"status\":\"active\"}]"
>```
>
>2.7.4) Move back to the client app directory and restart the client app service
>>`cd /etc/hyperledger/fabric/setup/client`
>
>>`go run main.go`

<br>

**2.8) cloudcityinc CLI**
<br>Switch back to the cloudcityinc terminal window
<br>Start a Bash session in the cloudcityinc CLI admin portal
>`docker exec -it cloudcityinc-cli bash`

#### The following step occurs inside the cloudcityinc CLI Bash session:
>2.8.1) Join the channel and install the chaincode (this may take a few minutes)
>>`. /etc/hyperledger/fabric/setup/add_org/add_org_install_cc.sh`
>
>The terminal should show success in querying a sample entry. e.g.:
>```
>Chaincode invoke successful. result: status:200 payload:"[{\"balance\":1000000000,\"docType\":\"wallet\",\"owner\":\"CloudCity\",\"status\":\"active\"}]"
>```

<br>2.8.2) View the cloudcityinc CouchDB World State entries by going to http://localhost:6984/_utils
<br>NOTE: This port was exposed in the "cloudcityinc-couchdb" `docker-compose.yaml` file.  Due to security concerns, the port should not be exposed in production.
<br><br>You will need to log in using the username / password used in the couchdb container.  The default is:
<br>username: cloudcityinc-couchdb
<br>password: couchdb
<br><br>You will notice that not only was the Wallet chaincode `create` command successful in creating the example account ("CloudCity" in this case), but the cloudcityinc peer already recreated the existing blockchain data in the World State database
<br><br>![couchdb wallet](./readme_media/org2_couchdb_wallet.png)

<br>

**2.9) cloudcityinc CLIENT APP**
#### The following step occurs inside the cloudcityinc CLI Bash session:
>2.9.1) Move to the client app directory and start the client app service (on :3001 port this time)
>>`cd /etc/hyperledger/fabric/setup/client`
>
>>`go run main.go`

2.9.2) Open a new browser session (such as a private session) and load http://localhost:3001 to view the app

2.9.3) Log into the cloudcityinc client app
<br>NOTE: This example app does not restrict access to a client app by organization, but new accounts created via the client app will assign the client app's organization to that new User (for example, creating a new account via the http://localhost:3001 app will create a new User for cloudcityinc)

<br>You can see cloudcityinc's World State data includes all ledger data
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