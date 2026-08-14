#!/bin/sh
# deepseek-harness-docker entrypoint.
#
# Modes (first argument):
#   (default)   run the WeChat bot:          dsh --profile weixin
#   setup       one-shot QR login:           dsh-wechat-setup
#   headless    one-shot CLI task:           dsh --profile headless <task...>
#   web         run the Web UI (localhost):  dsh --profile web
#   shell       drop into a shell            /bin/sh
#
# The `weixin` profile is baked into the image at /opt/dsh-home-baked. On first
# boot against an empty $DSH_HOME (a mounted volume), seed it so the bot needs
# no network access at runtime.
set -e

seed_home() {
  if [ -d "$DSH_HOME/profiles" ]; then
    return
  fi
  mkdir -p "$DSH_HOME"
  cp -a /opt/dsh-home-baked/. "$DSH_HOME"/
  echo "seeded fresh DSH_HOME at $DSH_HOME"
}

cmd="${1:-weixin}"
case "$cmd" in
  setup)
    # QR login needs only the bridge's dist + qrcode-terminal.
    exec node /opt/dsh-wechat-bridge/dist/setup.js
    ;;
  web)
    seed_home
    exec dsh --profile web "$@"
    ;;
  headless)
    seed_home
    shift
    exec dsh --profile headless "$@"
    ;;
  shell|sh|bash)
    seed_home
    exec /bin/sh
    ;;
  weixin|run|bot|*)
    seed_home
    exec dsh --profile weixin "$@"
    ;;
esac
