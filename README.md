# nifi-docker-compose

This project contains some examples of how I run NiFi for testing locally.

## No TLS

### No Swarm
```bash
docker-compose up -d
```

### With Swarm
```bash
docker stack deploy --compose-file docker-compose.yml nifi
```

## With TLS


First, I run the following scripts `create-ca.sh`, `create-server.sh`, and `create-user.sh` to generate
certs for a ca, server, and user.

### No Swarm
```bash
cd tlsdocker-compose up -d
```

### With Swarm
```bash
docker stack deploy --compose-file tls/docker-compose.yml tls-nifi
```

# Generating certs

We are going to generate 3 pairs of certs:
* A certificate authority cert
* A server cert
* A user cert

## Setup the Certificate Authority

The following command can be used to establish the CA crt. This example is only for
testing, and development because it uses a blank password.

```bash
cd certs
./create-ca.sh
```

## Setup the Server Cert

The following command can be used to establish the server crt. This example is only for
testing, and development because it uses a blank password.

```bash
cd certs
./create-server.sh
```

## Setup the User Cert
The following command can be used to establish the user crt. This example is only for
testing, and development because it uses a blank password.

```bash
cd certs
./create-user.sh
```