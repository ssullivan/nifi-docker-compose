project := "nifi-docker-compose"
cert_password := "changeit"
compose := "docker compose -p " + project + " -f docker-compose.yml"

# List available recipes
default:
    @just --list

# --- Stack ---

# Start NiFi (run `just certs-all` first)
up:
    CERT_PASSWORD={{cert_password}} {{compose}} up -d

# Stop NiFi
down:
    CERT_PASSWORD={{cert_password}} {{compose}} down

# Follow the NiFi logs
logs:
    CERT_PASSWORD={{cert_password}} {{compose}} logs -f nifi

# Block until the HTTPS listener answers (typically 15-60s after `just up`).
# The client cert is required even here: NiFi demands one during the TLS
# handshake, so an anonymous probe is reset rather than answered.
wait:
    until curl -s -o /dev/null --cacert certs/ca_crt.pem \
      --cert certs/user_crt.pem --key certs/user_key.pem --pass {{cert_password}} \
      https://localhost:8443/nifi-api/flow/current-user; do sleep 5; done
    @echo "NiFi is up: https://localhost:8443/nifi/"

# Stop NiFi and delete its volumes
clean-volumes: down
    docker volume ls -q --filter label=com.docker.compose.project={{project}} | xargs -r docker volume rm

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

# Print the DN NiFi derives from the user cert (must equal INITIAL_ADMIN_IDENTITY).
# sep_comma_plus_space matches how NiFi renders the principal -- plain RFC2253
# omits the spaces and will not match.
certs-dn:
    @openssl x509 -in certs/user_crt.pem -noout -subject -nameopt RFC2253,sep_comma_plus_space | sed 's/^subject= *//'

# Remove generated cert material for a clean re-run
clean-certs:
    rm -f certs/*.p12 certs/*.pem certs/*.csr certs/index.txt* certs/serial.txt*
    rm -rf certs/signed

# --- Verify ---

# Prove the UI authorizes the generated client cert as the initial admin
verify:
    curl -sS --cacert certs/ca_crt.pem \
      --cert certs/user_crt.pem --key certs/user_key.pem --pass {{cert_password}} \
      https://localhost:8443/nifi-api/flow/current-user
