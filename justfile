project := "nifi-docker-compose"
cert_password := "changeit"
compose := "docker compose -p " + project + " -f docker-compose.yml"
chrome_image := "nifi-verify-chrome"

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

# The client cert is required even here: NiFi demands one during the TLS
# handshake, so an anonymous probe is reset rather than answered.

# Block until the HTTPS listener answers (typically 15-60s after `just up`)
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

# sep_comma_plus_space matches how NiFi renders the principal -- plain RFC2253
# omits the spaces and will not match.

# Print the DN NiFi derives from the user cert (must equal INITIAL_ADMIN_IDENTITY)
certs-dn:
    @openssl x509 -in certs/user_crt.pem -noout -subject -nameopt RFC2253,sep_comma_plus_space | sed 's/^subject= *//'

# Remove generated cert material for a clean re-run
clean-certs:
    rm -f certs/*.p12 certs/*.pem certs/*.csr certs/index.txt* certs/serial.txt*
    rm -rf certs/signed

# --- Verify ---

# Prove the API authorizes the generated client cert as the initial admin
verify:
    curl -sS --cacert certs/ca_crt.pem \
      --cert certs/user_crt.pem --key certs/user_key.pem --pass {{cert_password}} \
      https://localhost:8443/nifi-api/flow/current-user

# Build the headless Chrome image used by `just verify-ui` (cached after first run)
chrome-image:
    @docker build -q -t {{chrome_image}} verify >/dev/null

# Render the UI in headless Chrome over two-way TLS and assert admin authorization
verify-ui: chrome-image
    #!/usr/bin/env bash
    set -euo pipefail

    # The check `verify` cannot make: curl only proves the API accepts the cert,
    # while this renders the Angular app the way a browser does. Needs the stack
    # up (`just up && just wait`). See verify/Dockerfile for why Chrome runs in a
    # container; --network host is what lets it reach localhost:8443.

    dn="$(openssl x509 -in certs/user_crt.pem -noout -subject \
            -nameopt RFC2253,sep_comma_plus_space | sed 's/^subject= *//')"

    chrome() {
      docker run --rm --network host -v "$PWD/certs:/certs:ro" \
        -e CERT_PASSWORD={{cert_password}} {{chrome_image}} \
        --virtual-time-budget=20000 --dump-dom "$1" 2>/dev/null
    }

    fail() { echo "FAIL: $1" >&2; exit 1; }

    echo "==> rendering https://localhost:8443/nifi/"
    ui="$(chrome https://localhost:8443/nifi/)"

    # A TLS or authorization failure still returns a DOM, so check for what only
    # a working UI contains rather than for the absence of an error.
    grep -qF '<title>NiFi Flow</title>' <<<"$ui" || fail "the NiFi UI did not load (TLS or proxy-host problem?)"
    grep -qF 'id="canvas"' <<<"$ui"           || fail "the UI loaded but never rendered the flow canvas"
    grep -qF "$dn" <<<"$ui"                   || fail "the UI did not report the client cert identity: $dn"

    echo "==> checking authorization"
    api="$(chrome https://localhost:8443/nifi-api/flow/current-user)"

    # NiFi emits compact JSON, so these substrings are exact. Authorization is
    # the interesting half: an unseeded admin still authenticates (200, correct
    # identity) but comes back with every permission false.
    grep -qF "\"identity\":\"${dn}\"" <<<"$api" || fail "authenticated as the wrong identity, expected: $dn"
    grep -qF '"anonymous":false' <<<"$api"      || fail "NiFi treated the request as anonymous"
    grep -qF '"controllerPermissions":{"canRead":true,"canWrite":true}' <<<"$api" \
      || fail "authenticated but not authorized -- INITIAL_ADMIN_IDENTITY likely does not match: $dn"

    echo
    echo "PASS: headless Chrome loaded the UI as ${dn}"

# Remove the headless Chrome image
clean-chrome:
    -docker rmi {{chrome_image}}
