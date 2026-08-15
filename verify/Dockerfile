# Headless Chrome that can actually talk to NiFi's two-way TLS.
#
# This lives in a container rather than using the host's Chrome because the
# client-certificate policy below can only be read from /etc/opt/chrome, which
# is root-owned on the host. In here we own the whole filesystem, so `just
# verify-ui` needs no sudo and leaves no trace on the host.
FROM debian:stable-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg libnss3-tools \
 && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

# Headless Chrome has no UI to draw the client-certificate picker with, so when
# NiFi asks for a certificate it blocks forever instead of failing. This policy
# makes the choice up front. The filter is deliberately empty: the throwaway
# NSS database built in entrypoint.sh holds exactly one client certificate, so
# "first match" is unambiguous, and leaving it empty means regenerating the CA
# under a different DN doesn't silently reintroduce the hang.
COPY policy.json /etc/opt/chrome/policies/managed/nifi-dev.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
