#!/usr/bin/env bash

openssl genrsa -out ca.key 2048
openssl req -new -x509 -key ca.key -out ca.crt -config ca.csr -batch
openssl pkcs12 -export -out ca.p12 -inkey ca.key -in ca.crt -passout pass:
