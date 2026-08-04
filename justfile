plain_project := "nifi-docker-compose"
tls_project := "nifi-docker-compose-tls"
cert_password := "changeit"

# List available recipes
default:
    @just --list

# --- Plain (no TLS) stack ---

# Start the non-TLS stack
up:
    docker compose -p {{plain_project}} -f docker-compose.yml up -d

# Stop the non-TLS stack
down:
    docker compose -p {{plain_project}} -f docker-compose.yml down

# Stop the non-TLS stack and delete its volumes
clean-volumes: down
    docker volume ls -q --filter label=com.docker.compose.project={{plain_project}} | xargs -r docker volume rm

# --- TLS stack ---

# Start the TLS stack (run `just certs-all` first)
up-tls:
    docker compose -p {{tls_project}} -f tls/docker-compose.yml up -d

# Stop the TLS stack
down-tls:
    docker compose -p {{tls_project}} -f tls/docker-compose.yml down

# Stop the TLS stack and delete its volumes
clean-volumes-tls: down-tls
    docker volume ls -q --filter label=com.docker.compose.project={{tls_project}} | xargs -r docker volume rm

# --- Certs ---

# Generate the CA cert
certs-ca:
    cd certs && CERT_PASSWORD={{cert_password}} ./create-ca.sh

# Generate and sign the server cert (requires certs-ca)
certs-server:
    cd certs && CERT_PASSWORD={{cert_password}} ./create-server.sh

# Generate and sign the user cert (requires certs-ca)
certs-user:
    cd certs && CERT_PASSWORD={{cert_password}} ./create-user.sh

# Generate CA, server, and user certs in order
certs-all: certs-ca certs-server certs-user

# Remove generated cert material for a clean re-run
clean-certs:
    rm -f certs/*.p12 certs/*.pem certs/*.csr certs/index.txt* certs/serial.txt*
    rm -rf certs/signed
