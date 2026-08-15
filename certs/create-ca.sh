#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# This is just for testing and development.
# NOTE: openssl-ca.cnf sets `encrypt_key = no`, so ca_key.pem is written
# UNENCRYPTED; -passout below only protects the PKCS12 bundle.
CERT_PASSWORD="${CERT_PASSWORD:-changeit}"

# -extensions is required: without it `req -x509` emits an X.509 v1 cert with
# no basicConstraints, which no browser will trust as a CA.
# -days is required too: `req -x509` defaults to 30 days, which would expire
# the CA long before the 1000-day certs it signs.
openssl req -x509 -config openssl-ca.cnf -extensions ca_extensions \
  -newkey rsa:4096 -sha256 -days 3650 \
  -passout pass:"$CERT_PASSWORD" -out ca_crt.pem -outform PEM -batch

# This bundle is NiFi's truststore. It would be tidier to build it with -nokeys
# so the CA private key stays out of the container, but neither alternative
# works here (both verified against apache/nifi:2.11.0):
#   * `pkcs12 -export -nokeys` produces a store Java reads as ZERO entries --
#     Java only treats a cert bag as a trustedCertEntry when it carries an
#     Oracle-specific attribute that OpenSSL cannot write. Only `keytool
#     -importcert` can, and that would make a JDK a prerequisite of this repo.
#   * TRUSTSTORE_TYPE=PEM is advertised by the image's secure.sh but NiFi 2.11
#     rejects it: "NoSuchAlgorithmException: PEM KeyStore not available".
# So the CA key rides along in ca.p12, and Java uses the PrivateKeyEntry's
# certificate as the trust anchor. Acceptable only because this is a disposable
# dev CA whose key is already sitting unencrypted in ca_key.pem.
openssl pkcs12 -export -out ca.p12 -inkey ca_key.pem -in ca_crt.pem \
  -passin pass:"$CERT_PASSWORD" -passout pass:"$CERT_PASSWORD"

mkdir -p signed
touch index.txt
echo '01' > serial.txt
