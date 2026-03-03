            FROM node:20-bookworm-slim AS builder

            WORKDIR /app

            # Install system deps needed by native addons:
            #   git          — required by node-llama-cpp and similar packages that
            #                  clone source during postinstall
            #   build-essential, python3 — for node-gyp compiled modules
            #   ca-certificates — for HTTPS git clones
            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git build-essential python3 ca-certificates \
                && rm -rf /var/lib/apt/lists/*

            RUN corepack enable && corepack prepare pnpm@latest --activate
            COPY pnpm-lock.yaml package.json ./
            COPY pnpm-workspace.yaml ./
            RUN pnpm install --frozen-lockfile
            COPY . .
            RUN pnpm install --frozen-lockfile
RUN pnpm ui:build
RUN pnpm run build

            FROM node:20-bookworm-slim
            WORKDIR /app
            ENV NODE_ENV=production

            # Runtime needs git + package manager available:
            #   git          — some modules do lazy git operations at startup
            #   corepack/pnpm/yarn — app may spawn `pnpm exec ...` or `yarn ...` at runtime
            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git ca-certificates \
                && rm -rf /var/lib/apt/lists/*
            RUN npm install -g pnpm

            COPY --from=builder /app ./

            RUN groupadd -r appgroup && useradd -r -g appgroup appuser
            USER appuser

            EXPOSE 18789
            # No healthcheck for non-web app
            CMD ["npm", "start"]
