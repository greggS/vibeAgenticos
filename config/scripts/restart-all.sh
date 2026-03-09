#!/bin/sh
# Restart OpenClaw gateway + bridge + Chromium kiosk
export PATH="$HOME/.npm-global/bin:$PATH"
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/1000

# Kill by port/PID to avoid accidentally killing SSH session
for pid in $(fuser 18790/tcp 2>/dev/null); do kill "$pid" 2>/dev/null; done
for pid in $(fuser 18791/tcp 2>/dev/null); do kill "$pid" 2>/dev/null; done
for pid in $(pgrep -f 'chromium.*kiosk' 2>/dev/null); do kill "$pid" 2>/dev/null; done
fuser -k 18789/tcp 2>/dev/null
sleep 3

nohup openclaw gateway > /tmp/gateway.log 2>&1 &
sleep 4

rm -rf /tmp/chromium-main
nohup node ~/.openclaw/bridge/openclaw-bridge.js > /tmp/bridge.log 2>&1 &
sleep 3

setsid nohup chromium-browser \
  --kiosk \
  --app=http://127.0.0.1:8080/main.html \
  --user-data-dir=/tmp/chromium-main \
  --ozone-platform=wayland --no-sandbox \
  --disable-web-security --allow-running-insecure-content \
  --no-first-run --disable-infobars \
  --disable-gpu --use-gl=swiftshader \
  > /tmp/main-chrome.log 2>&1 < /dev/null &
