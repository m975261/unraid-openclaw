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
            # Use pnpm's default home for root — avoids any path mismatch with
            # the managed-tools bootstrap which hardcodes this location.
            ENV PNPM_HOME=/root/.local/share/pnpm
            ENV PATH=/root/.local/share/pnpm/bin:$PATH

            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git ca-certificates curl \
                && rm -rf /var/lib/apt/lists/*

            RUN npm install -g pnpm@latest

            COPY --from=builder /app ./

            # Pre-bootstrap pnpm managed-tools so `pnpm exec <tool>` never
# downloads at container startup (requires no network at runtime).
RUN pnpm add pnpm@latest \
        --loglevel=error \
        --ignore-scripts \
        --config.strict-dep-builds=false \
        --config.node-linker=hoisted \
        --config.bin=bin \
    || true

            EXPOSE 18789
            # No healthcheck for non-web app
            CMD ["npm", "start"]
