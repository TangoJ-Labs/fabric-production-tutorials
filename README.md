# Hyperledger Fabric Production Setup Tutorials

**OCT 2018 UPDATE**: NodeOU and confixtx.yaml v1.2 features have been added (with ".peer" endorsement policy used)
<br>**SEP 2018 UPDATE**: Please note the changes to the MSP trees (specifically the `/users` directory tree)

Most Hyperledger Fabric examples provide highly automated network setup scripts that do not handle cryptographic data in a way that resembles a production environment with isolated organizations, differing setup timelines, etc.

### This repository provides tutorials for ***intentionally manual*** network setup procedures.  These packages are *not* intended for a quick startup, but to provide:
- Education regarding the general layout of a Hyperledger Fabric network
- Demonstrations of best practices procedures for production environment setups

<br>
<br>

---
## The [/outer_rim_trade](./outer_rim_trade) tutorial creates a space-based trade network using a single orderer.
- TEST A BROWSER INTERFACE using the Go SDK and a React.js front-end.  Transfer credits between users via the GUI interface.

## The [/orderer_solo](./orderer_solo) example now includes updated MSP tree structures.
- This example includes the steps necessary to set up two isolated organizations on one network with a single channel.  Setup occurs sequentially, NOT simultaneously, mimicking a production environment with organizations operating separately on different setup timelines.

## The [/orderer_scalable](./orderer_scalable) example is under construction.

<br>

## Check out the [CRYPTO](CRYPTO.md) page to better understand the MSP tree
- **TIP: Be sure to scroll to the bottom of the CRYPTO page to see a layout of the MSP tree created by the `cryptogen` tool (used in most Fabric examples)**
---

<br>
<br>

## Contributions are greatly appreciated!

<br>

## PLANNED UPGRADES:
- Kafka (w/ Docker Swarm) network