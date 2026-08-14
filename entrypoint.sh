#!/bin/sh
# deepseek-harness-docker entrypoint.
#
# Modes:
#   (default)  run the WeChat bridge:  dsh --profile weixin
#   setup      one-shot QR login:       dsh-wechat-setup
#   web        run the Web UI instead:  dsh --profile web
#
# The `weixin` profile is baked into the image at /opt/dsh-home. On first boot
# against a different/empty $DSH_HOME (e.g. a mounted volume), seed it so the
# bot needs no network access at runtime.
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
  weixin|run|bot|*)
    seed_home
    exec dsh --profile weixin "$@"
    ;;
esac
