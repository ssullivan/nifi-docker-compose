#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

CERT_PASSWORD="${CERT_PASSWORD:-changeit}"

openssl req -config openssl-user.cnf -newkey rsa:4096 -sha256 \
  -passout pass:"$CERT_PASSWORD" -out user.csr -outform PEM -batch

openssl ca -batch -config openssl-ca.cnf -policy signing_policy \
  -extensions user_signing_req -out user_crt.pem -infiles user.csr

# -certfile includes the CA cert so the bundle imports cleanly into a browser.
openssl pkcs12 -export -out user.p12 -inkey user_key.pem -in user_crt.pem \
  -certfile ca_crt.pem \
  -passin pass:"$CERT_PASSWORD" -passout pass:"$CERT_PASSWORD"
