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
            # Tell pnpm to store its tools cache inside /app which appuser owns.
            # Without this, `pnpm exec <tool>` tries to mkdir under /home/appuser/.local
            # which either doesn't exist or has wrong permissions → EACCES.
            ENV PNPM_HOME=/app/.pnpm-home
            ENV PATH=/app/.pnpm-home:$PATH

            # Runtime needs git + pnpm available to any user:
            #   git          — some modules do lazy git operations at startup
            #   pnpm         — app may spawn `pnpm exec ...` at runtime (e.g. tsdown)
            RUN apt-get update && apt-get install -y --no-install-recommends \
                    git ca-certificates \
                && rm -rf /var/lib/apt/lists/*
            RUN npm install -g pnpm

            COPY --from=builder /app ./

            # Create appuser and give them ownership of the entire /app tree
            # including the pnpm tools cache directory.
            RUN groupadd -r appgroup && useradd -r -g appgroup -d /app appuser \
                && mkdir -p /app/.pnpm-home \
                && chown -R appuser:appgroup /app
            USER appuser

            EXPOSE 18789
            # No healthcheck for non-web app
            CMD ["npm", "start"]
