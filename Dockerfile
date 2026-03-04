            # syntax=docker/dockerfile:1
            # ── Builder ─────────────────────────────────────────────────────
            # Full bookworm (not slim): native addons need glibc + build tools.
            # Alpine/musl breaks prebuilt binaries (canvas, sharp, bcrypt, etc.)
            FROM node:22-bookworm AS builder
            WORKDIR /app
            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git build-essential python3 ca-certificates curl \
                && rm -rf /var/lib/apt/lists/*
            RUN corepack enable && corepack prepare pnpm@latest --activate
            COPY pnpm-lock.yaml package.json ./
            COPY pnpm-workspace.yaml ./
            RUN pnpm install --frozen-lockfile
            COPY . .
            RUN pnpm ui:build
RUN pnpm run build

            # ── Runtime ─────────────────────────────────────────────────────
            FROM node:22-bookworm-slim
            WORKDIR /app
            ENV NODE_ENV=production
            # node_modules/.bin on PATH: locally-installed CLI tools are found
            # by both shell-form CMD and interactive docker exec sessions.
            ENV PATH=/app/node_modules/.bin:$PATH
            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git ca-certificates curl gosu \
                && rm -rf /var/lib/apt/lists/*
            RUN corepack enable && corepack prepare pnpm@latest --activate
            COPY --from=builder /app ./
            RUN printf '#!/bin/sh\n# TITAN Unraid Dockerizer — PUID/PGID entrypoint\nset -e\nPUID=${PUID:-99}\nPGID=${PGID:-100}\ngetent group appgroup >/dev/null 2>&1 || addgroup -g "$PGID" appgroup 2>/dev/null || addgroup --gid "$PGID" appgroup 2>/dev/null || true\ngetent passwd appuser >/dev/null 2>&1 || adduser -u "$PUID" -G appgroup -s /bin/sh -D appuser 2>/dev/null || adduser --uid "$PUID" --gid "$PGID" --shell /bin/sh --no-create-home --disabled-password appuser 2>/dev/null || true\nchown -R "$PUID:$PGID" /data /config 2>/dev/null || true\nexec gosu appuser "$@"\n' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh
VOLUME ["/data", "/config"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
            EXPOSE 18789
            LABEL org.opencontainers.image.source="https://github.com/openclaw/openclaw" \
      org.opencontainers.image.description="Auto-containerized by TITAN Unraid Dockerizer v2.9"
            # No healthcheck — non-web app
            CMD ["npm", "start"]
