#!/bin/sh
# TITAN Unraid Dockerizer — PUID/PGID entrypoint
# Runs as root, drops to app user with host UID/GID.
# Set PUID=99 PGID=100 (Unraid nobody:users) or your own IDs.
set -e

PUID=${PUID:-99}
PGID=${PGID:-100}

# Create group with target GID
getent group appgroup > /dev/null 2>&1 \
  || addgroup -g "$PGID" appgroup 2>/dev/null \
  || addgroup --gid "$PGID" appgroup 2>/dev/null \
  || true

# Create user with target UID
getent passwd appuser > /dev/null 2>&1 \
  || adduser -u "$PUID" -G appgroup -s /bin/sh -D appuser 2>/dev/null \
  || adduser --uid "$PUID" --gid "$PGID" --shell /bin/sh --no-create-home --disabled-password appuser 2>/dev/null \
  || true

# Fix ownership on data volumes
chown -R "$PUID:$PGID" /data /config 2>/dev/null || true

# Drop to app user and exec the main process
exec su-exec appuser "$@"
