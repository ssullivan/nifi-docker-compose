# nifi-docker-compose

A single-node Apache NiFi 2.11.0 stack for local testing, using two-way TLS
(client certificate) authentication with a throwaway CA generated in `certs/`.

NiFi 2.x is HTTPS-only, so there is no separate "plain" stack — there is one
`docker-compose.yml` and you log in with a client certificate rather than a
username and password.

**This is for testing and development only.** The CA, its key, and every
password here are disposable; never reuse this setup or its OpenSSL configs for
anything real.

## Prerequisites

Docker with Compose v2, `openssl`, and `curl`. The included `justfile` wraps
every command below — install [`just`](https://github.com/casey/just) (e.g.
`brew install just` or `apt install just`), or run the commands in each recipe
directly.

## Quick start

```bash
just certs-all   # generate the CA, server, and user certs
just up          # start NiFi
just wait        # block until the HTTPS listener answers (15-60s, plus the image pull on first run)
just verify      # prove the client cert authenticates as the initial admin
```

`just verify` should print a JSON body containing
`"identity":"CN=NifiAdmin, O=Test, L=Baltimore, ST=MD, C=US"`,
`"anonymous":false`, and `canRead`/`canWrite` both `true` under
`controllerPermissions`, `policiesPermissions`, and `tenantsPermissions`.
(`provenance`, `counters`, and `system` stay `false` — NiFi does not grant those
to the initial admin, so a `403` from `/nifi-api/system-diagnostics` is normal.)

Then open <https://localhost:8443/nifi/>.

NiFi requires a client certificate during the TLS handshake, so a request
without one is refused at the TLS layer rather than answered with a `401`:

```
curl: (56) OpenSSL SSL_read: ... tlsv13 alert certificate required
```

## Logging in from a browser

There is no username/password login. You need two things in your browser:

1. **Trust the CA.** Import `certs/ca_crt.pem` as a trusted certificate
   authority (Firefox: Settings → Privacy & Security → View Certificates →
   Authorities → Import, and tick "identify websites"). Without this you get a
   certificate warning.
2. **Import your client cert.** Import `certs/user.p12` (password `changeit`)
   into your personal certificate store.

Open <https://localhost:8443/nifi/> and pick the `NifiAdmin` certificate when
prompted. The server certificate covers `localhost`, `localhost.localdomain`,
`127.0.0.1`, and `::1`; any other hostname will fail verification.

## Generating certs

Three pairs get generated, all into `certs/`:

* a certificate authority (`ca_crt.pem`, `ca_key.pem`, `ca.p12`)
* a server cert for NiFi (`server_crt.pem`, `server_key.pem`, `server.p12`)
* a user cert for you (`user_crt.pem`, `user_key.pem`, `user.p12`)

`just certs-all` runs all three in order; `just certs-ca`, `just certs-server`,
and `just certs-user` run them individually. They share one password —
`changeit` by default:

```bash
just --set cert_password hunter2 certs-all
just --set cert_password hunter2 up
```

The password has to match on both commands: `docker-compose.yml` reads
`${CERT_PASSWORD:-changeit}` for the keystore and truststore, and the `just`
recipes are what put `CERT_PASSWORD` in the environment.

Only `server.p12` (NiFi's keystore) and `ca.p12` (its truststore) are mounted
into the container. `ca.p12` does carry the CA private key: a keyless PKCS12 is
unreadable to Java without `keytool`, and NiFi 2.11 rejects `PEM` truststores
despite advertising them. `certs/create-ca.sh` documents both dead ends. That is
tolerable only because this CA is disposable — do not copy the pattern.

### The admin identity must match the user cert

`INITIAL_ADMIN_IDENTITY` in `docker-compose.yml` has to equal the user cert's
subject exactly — that is the string NiFi derives from the certificate. Check
it with:

```bash
just certs-dn
# CN=NifiAdmin, O=Test, L=Baltimore, ST=MD, C=US
```

**Mind the spaces after each comma.** NiFi renders the principal that way, so
the bare RFC 2253 form (`CN=NifiAdmin,O=Test,...`) does not match. If the two
differ, the failure is quiet rather than loud: the certificate still
authenticates and `/nifi-api/flow/current-user` still returns `200`, but every
entry under `*Permissions` comes back `false` and the UI is an empty canvas with
no menus.

## Starting over

```bash
just clean-volumes   # stop NiFi and delete its volumes
just clean-certs     # remove all generated cert material
```

**Regenerating certs or changing `INITIAL_ADMIN_IDENTITY` requires
`just clean-volumes` first.** NiFi's entrypoint only writes the admin identity
into `conf/authorizers.xml` when the element is still empty, and `users.xml` /
`authorizations.xml` are seeded once on first boot and never reconciled. Against
an existing `conf` volume the change silently does nothing and locks you out.
When in doubt about an auth failure, clean the volumes and start again.

## Notes

* Site-to-site (port 10000) is not published. To enable it, add `- "10000:10000"`
  to `ports` and `- NIFI_REMOTE_INPUT_HOST=localhost` to `environment` —
  otherwise NiFi advertises the container ID as its hostname and no peer on the
  host can reach it.
* Docker Swarm is not supported here; the stack uses local named volumes.
