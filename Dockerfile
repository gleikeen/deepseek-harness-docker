# syntax=docker/dockerfile:1
#
# deepseek-harness-docker — Docker packaging of DeepSeek Harness (dsh) with the
# WeChat bridge plugin.
#
# dsh comes from the published npm package (the officially documented path,
# `npx @deepseek-ai/dsh web`); the bridge plugin is built from source. The
# `weixin` profile is baked at build time so the container needs no network at
# runtime beyond the WeChat/model APIs.
#
# Build:
#   docker build -t dsh-weixin --build-arg DSH_VERSION=0.1.0-rc.6 --build-arg BRIDGE_REF=master .

FROM node:22-bookworm-slim

ARG DSH_VERSION=0.1.0-rc.6
ARG BRIDGE_REF=master

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN corepack enable && corepack prepare pnpm@11.7.0 --activate

# git is needed to clone the bridge; ca-certificates for https.
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# 1. dsh CLI (published package; pulls the full host plugin tree).
RUN npm install -g "@deepseek-ai/dsh@${DSH_VERSION}"

# 2. WeChat bridge plugin, built from source.
#    --legacy-peer-deps: the bridge's peer deps resolve from the dsh install at
#    runtime; the dev-only type resolution tolerates the prerelease ranges.
WORKDIR /opt/dsh-wechat-bridge
# BRIDGE_REF must be a branch or tag (shallow single-branch clone).
RUN git clone --depth 1 --branch "${BRIDGE_REF}" --single-branch https://github.com/gleikeen/dsh-wechat-bridge.git .
RUN npm install --legacy-peer-deps && npm run build

# 3. Bake the `weixin` profile (dsh-base + bridge bundle) into a staging home.
#    At runtime the entrypoint seeds it into $DSH_HOME (usually a mounted
#    volume) on first boot, so the container needs no network at runtime.
ENV DSH_HOME=/opt/dsh-home-baked
RUN dsh plugin --profile weixin add file:/opt/dsh-wechat-bridge

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV DSH_HOME=/opt/dsh-home
ENV NODE_ENV=production

# The Web UI can also be served from this image (`docker run ... web`).
EXPOSE 3080

ENTRYPOINT ["/entrypoint.sh"]
