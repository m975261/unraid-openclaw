      # syntax=docker/dockerfile:1
      # ── Official image wrapper ───────────────────────────────────────
      # This project publishes an official image: ghcr.io/openclaw/openclaw:latest
      # We re-tag it with Unraid metadata rather than building from source.
      # Building from source is fragile (Bun, native modules, pnpm workspaces)
      # and unnecessary when upstream provides a production-grade multi-arch image.
      FROM ghcr.io/openclaw/openclaw:latest
      LABEL org.opencontainers.image.source="https://github.com/openclaw/openclaw" \
org.opencontainers.image.description="Auto-containerized by TITAN Unraid Dockerizer v2.9"
      EXPOSE 18789
      # No healthcheck — non-web app
