#!/bin/sh
# Build a throwaway NSS database from the mounted certs, then hand off to Chrome.
#
# Chrome on Linux does not read the system CA bundle for user-added roots, and
# never reads client certificates from disk -- both come from NSS at
# $HOME/.pki/nssdb. The database is rebuilt on every run so it always matches
# whatever `just certs-all` last produced.
set -eu

: "${CERT_PASSWORD:=changeit}"
DB="$HOME/.pki/nssdb"

mkdir -p "$DB"
certutil -N -d "sql:$DB" --empty-password
# CT,C,C = trusted CA for TLS servers, so the self-signed NiFi cert validates.
certutil -A -d "sql:$DB" -n "NiFi Dev CA" -t "CT,C,C" -i /certs/ca_crt.pem
pk12util -i /certs/user.p12 -d "sql:$DB" -W "$CERT_PASSWORD" -K "" >/dev/null

exec google-chrome \
  --headless \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  "$@"
