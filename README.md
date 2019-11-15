# nifi-docker-compose

Example nifi docker-compose setup

```bash
docker-compose up -d
```

```bash
docker stack deploy --compose-file docker-compose.yml nifi
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