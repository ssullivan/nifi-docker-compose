#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

CERT_PASSWORD="${CERT_PASSWORD:-changeit}"

openssl req -config openssl-server.cnf -newkey rsa:4096 -sha256 \
  -passout pass:"$CERT_PASSWORD" -out server.csr -outform PEM -batch

openssl ca -batch -config openssl-ca.cnf -policy signing_policy \
  -extensions server_signing_req -out server_crt.pem -infiles server.csr

# -certfile ships the CA cert in the keystore so Jetty presents a full chain.
openssl pkcs12 -export -out server.p12 -inkey server_key.pem -in server_crt.pem \
  -certfile ca_crt.pem \
  -passin pass:"$CERT_PASSWORD" -passout pass:"$CERT_PASSWORD"
