# nifi-docker-compose

This project contains some examples of how I run NiFi for testing locally.

## Prerequisites

The included `justfile` wraps the commands below. Install [`just`](https://github.com/casey/just)
(e.g. `brew install just` or `apt install just`) to use it, or run the underlying
`docker compose`/shell commands shown in each recipe directly.

## No TLS

### No Swarm

The following command can be used to start nifi using docker-compose.
When nifi is started for the first time it will generate temporary credentials 
for single userlogin.

These credentials can be seen in the container logs and look like the following

```shell
nifi-docker-compose-nifi-1  | Generated Username [some_generated_username]
nifi-docker-compose-nifi-1  | Generated Password [some_generated_password]
```

These will be required to login to the web interface.

```bash
just up
```

The UI is at <https://localhost:8443/nifi>. NiFi only serves plain HTTP when
`NIFI_WEB_HTTP_PORT` is set, which this stack does not do, so the container
listens on 8443 over TLS with a self-signed cert — expect a browser warning.

### Starting Over

In order to start over the containers will need to be stopped and the volumes will
have to be deleted.

This can be done with a single command:

```bash
just clean-volumes
```

### With Swarm
```bash
docker stack deploy --compose-file docker-compose.yml nifi
```

## With TLS

First, generate certs for a ca, server, and user:

```bash
just certs-all
```

### No Swarm
```bash
just up-tls
```

The UI is at <https://localhost:8443/nifi>. Import `certs/user.p12` (password
`changeit`) into your browser first — the stack authenticates with client
certificates, so there is no username/password login. The server cert covers
`localhost`, `localhost.localdomain`, and `127.0.0.1`; other hostnames will
fail verification.

### Starting Over

```bash
just clean-volumes-tls
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

These are only for testing and development: they all share the same password
(`changeit` by default, override with `just --set cert_password <password> certs-all`).
`just certs-all` runs all three in order; each can also be run individually.

## Setup the Certificate Authority

```bash
just certs-ca
```

## Setup the Server Cert

```bash
just certs-server
```

## Setup the User Cert

```bash
just certs-user
```

## Starting Over

To remove all generated cert material and start fresh:

```bash
just clean-certs
```