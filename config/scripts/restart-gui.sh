#!/bin/sh
# Restart bridge + Chromium kiosk window
export PATH="$HOME/.npm-global/bin:$PATH"
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/1000

pkill -f openclaw-bridge 2>/dev/null
pkill -f chrome 2>/dev/null
sleep 2

rm -rf /tmp/chromium-main
nohup node ~/.openclaw/bridge/openclaw-bridge.js > /tmp/bridge3.log 2>&1 &
sleep 3

nohup chromium-browser \
  --kiosk \
  --app=http://127.0.0.1:8080/main.html \
  --user-data-dir=/tmp/chromium-main \
  --ozone-platform=wayland --no-sandbox \
  --disable-web-security --allow-running-insecure-content \
  --no-first-run --disable-infobars \
  --disable-gpu --use-gl=swiftshader \
  > /tmp/main-chrome.log 2>&1 &
