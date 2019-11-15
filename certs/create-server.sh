#!/usr/bin/env bash

mkdir -p server
openssl genrsa -out server/server.key 2048
openssl req -new -newkey rsa:2048 -nodes -keyout server/server.key -out server/server.csr

openssl pkcs12 -export -out server.p12 -inkey server.key -in server.crt -passout pass:
