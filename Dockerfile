            FROM node:20-bookworm-slim AS builder

            WORKDIR /app

            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git build-essential python3 ca-certificates curl \
                && rm -rf /var/lib/apt/lists/*

            RUN corepack enable && corepack prepare pnpm@latest --activate
            COPY pnpm-lock.yaml package.json ./
            COPY pnpm-workspace.yaml ./
            RUN pnpm install --frozen-lockfile
            COPY . .
            RUN pnpm install --frozen-lockfile
RUN pnpm ui:build
RUN pnpm run build

            # ── Runtime stage ────────────────────────────────────────────────
            FROM node:20-bookworm-slim
            WORKDIR /app

            ENV NODE_ENV=production
            # PNPM_HOME inside /app so pnpm exec tool-downloads land somewhere
            # writable when running as root. Also ensures tools survive restarts
            # if /app is bind-mounted as an Unraid appdata path.
            ENV PNPM_HOME=/app/.pnpm-store
            ENV PATH=/app/.pnpm-store/bin:$PATH

            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git ca-certificates curl \
                && rm -rf /var/lib/apt/lists/*

            RUN npm install -g pnpm

            COPY --from=builder /app ./

            # Pre-create pnpm store dir so first pnpm exec doesn't need to mkdir
            RUN mkdir -p /app/.pnpm-store/bin

            EXPOSE 18789
            # No healthcheck for non-web app
            CMD ["npm", "start"]
