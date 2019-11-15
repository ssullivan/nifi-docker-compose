#!/usr/bin/env bash

openssl req -config openssl-server.cnf -newkey rsa:4096 -passout pass:changeit  -sha256 -out server.csr -outform PEM -batch
openssl ca -batch -config openssl-ca.cnf -policy signing_policy -extensions signing_req -out server_crt.pem -infiles server.csr
openssl pkcs12 -export -out server.p12 -inkey server_key.pem -in server_crt.pem -passout pass:changeit
