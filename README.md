# Hyperledger Fabric Production Setup Tutorials

Most Hyperledger Fabric examples provide highly automated network setup scripts that do not handle cryptographic data in a way that resembles a production environment with isolated organizations, differing setup timelines, etc.

### This repository provides tutorials for **intentionally manual** network setup procedures.  These packages are *not* intended for a quick setup, but to provide:
- Education regarding the general layout of a Hyperledger Fabric network
- Demonstrations of best practices procedures for production environment setups

<br>
<br>

## Check out the [CRYPTO](CRYPTO.md) page to better understand the MSP tree
- **TIP: Be sure to scroll to the bottom of the CRYPTO page to see a layout of the MSP tree created by the `cryptogen` tool (used in most Fabric examples)**

<br>
<br>
<br>
<br>

## UPDATES PLANNED:
- SDK examples (golang)
- Kafka (w/ Docker Swarm) network
- `configtx.yaml` v1.2 (with Profile section, etc.)
- NodeOU utilization for use of ".peer", ".client", etc. in endorsement policy