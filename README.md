# nifi-docker-compose

This project contains some examples of how I run NiFi for testing locally.

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
docker-compose up -d
```

### Starting Over

In order to start over the containers will need to be stopped to stopped and the volumes will
have to be deleted.

This can be done by using the following commands

```shell
docker-compose down 
```

```shell
./local_remove_volumes.sh
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