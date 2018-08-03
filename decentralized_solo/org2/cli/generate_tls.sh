#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Generate client TLS cert and key pair for the peer CLI
fabric-ca-client enroll -d --enrollment.profile tls -u https://org2-admin:adminpw@org2-ca:7054 -M /tmp/tls --csr.hosts org2-cli

# Copy the TLS key and cert to the common directory
mkdir /data/tls || true
cp /tmp/tls/signcerts/* /data/tls/org2-cli-client.crt
cp /tmp/tls/keystore/* /data/tls/org2-cli-client.key
rm -rf /tmp/tls