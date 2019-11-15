#!/usr/bin/env bash

# This is just for testing and development
# For a real use case you would want to set a password on the ca (don't use the -nodes option)
openssl req -x509 -config openssl-ca.cnf -newkey rsa:4096 -sha256 -nodes -out ca_crt.pem -outform PEM -batch
openssl pkcs12 -export -out ca.p12 -inkey ca_key.pem -in ca_crt.pem -passout pass:
touch index.txt
echo '01' > serial.txt