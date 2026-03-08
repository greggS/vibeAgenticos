#!/bin/bash
# AgenticOS Install Script
# Usage: curl -fsSL https://raw.githubusercontent.com/greggS/vibeAgenticos/main/install.sh | bash
#
# Assumes: Ubuntu 24.04, OpenClaw already installed and configured

set -e

REPO="https://raw.githubusercontent.com/greggS/vibeAgenticos/main"
OPENCLAW_DIR="$HOME/.openclaw"
UI_DIR="$OPENCLAW_DIR/ui-custom"
BRIDGE_DIR="$OPENCLAW_DIR/bridge"
SCRIPTS_DIR="$OPENCLAW_DIR/scripts"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"
LABWC_DIR="$HOME/.config/labwc"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${BLUE}[AgenticOS]${NC} $1"; }
ok()   { echo -e "${GREEN}[AgenticOS]${NC} $1"; }
warn() { echo -e "${YELLOW}[AgenticOS]${NC} $1"; }

log "Starting AgenticOS install..."

# ── 1. System packages ────────────────────────────────────────────────────────
log "Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y \
  labwc \
  foot \
  chromium-browser \
  nodejs \
  npm \
  python3 \
  grim \
  pulseaudio \
  curl \
  git \
  2>/dev/null || \
sudo apt-get install -y \
  labwc \
  foot \
  chromium \
  nodejs \
  npm \
  python3 \
  grim \
  pulseaudio \
  curl \
  git

ok "System packages installed."

# ── 2. Node ws module ─────────────────────────────────────────────────────────
log "Installing Node.js ws module..."
mkdir -p "$BRIDGE_DIR"
if [ ! -f "$BRIDGE_DIR/package.json" ]; then
  echo '{"name":"openclaw-bridge","version":"1.0.0","dependencies":{"ws":"^8.0.0"}}' > "$BRIDGE_DIR/package.json"
fi
cd "$BRIDGE_DIR" && npm install --silent
ok "ws module installed."

# ── 3. UI files ───────────────────────────────────────────────────────────────
log "Installing UI files..."
mkdir -p "$UI_DIR"
curl -fsSL "$REPO/ui/main.html"           -o "$UI_DIR/main.html"
curl -fsSL "$REPO/ui/agents-content.html" -o "$UI_DIR/agents-content.html"
ok "UI files installed."

# ── 4. Bridge ─────────────────────────────────────────────────────────────────
log "Installing bridge..."
curl -fsSL "$REPO/bridge/openclaw-bridge.js" -o "$BRIDGE_DIR/openclaw-bridge.js"
ok "Bridge installed."

# ── 5. Scripts ────────────────────────────────────────────────────────────────
log "Installing scripts..."
mkdir -p "$SCRIPTS_DIR"
curl -fsSL "$REPO/config/scripts/restart-gui.sh"      -o "$SCRIPTS_DIR/restart-gui.sh"
curl -fsSL "$REPO/config/scripts/restart-all.sh"      -o "$SCRIPTS_DIR/restart-all.sh"
curl -fsSL "$REPO/config/scripts/toggle-terminal.sh"  -o "$SCRIPTS_DIR/toggle-terminal.sh"
chmod +x "$SCRIPTS_DIR/"*.sh
ok "Scripts installed."

# ── 6. AGENTS.md ──────────────────────────────────────────────────────────────
log "Installing AGENTS.md..."
mkdir -p "$WORKSPACE_DIR"
curl -fsSL "$REPO/config/openclaw/AGENTS.md" -o "$WORKSPACE_DIR/AGENTS.md"
ok "AGENTS.md installed."

# ── 7. Patch openclaw.json — add grok-4-1-fast model config ──────────────────
log "Patching openclaw.json..."
OPENCLAW_JSON="$OPENCLAW_DIR/openclaw.json"
if [ -f "$OPENCLAW_JSON" ]; then
  if ! grep -q "grok-4-1-fast" "$OPENCLAW_JSON"; then
    python3 - <<'PYEOF'
import json, os, sys
path = os.path.expanduser("~/.openclaw/openclaw.json")
with open(path) as f:
    cfg = json.load(f)

models = cfg.setdefault("models", {}).setdefault("providers", {}).setdefault("xai", {}).setdefault("models", [])
ids = [m.get("id") for m in models]

if "grok-4-1-fast" not in ids:
    models.append({
        "id": "grok-4-1-fast",
        "name": "Grok 4.1 Fast",
        "reasoning": False,
        "input": ["text"],
        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
        "contextWindow": 131072,
        "maxTokens": 32768
    })
    with open(path, "w") as f:
        json.dump(cfg, f, indent=4)
    print("  Added grok-4-1-fast model config.")
else:
    print("  grok-4-1-fast already present, skipping.")
PYEOF
  else
    warn "grok-4-1-fast already in openclaw.json, skipping."
  fi
else
  warn "openclaw.json not found at $OPENCLAW_JSON — skipping model patch."
  warn "Make sure OpenClaw is configured before running this script."
fi
ok "openclaw.json patched."

# ── 8. labwc config ───────────────────────────────────────────────────────────
log "Installing labwc config..."
mkdir -p "$LABWC_DIR"
curl -fsSL "$REPO/config/labwc/rc.xml"    -o "$LABWC_DIR/rc.xml"
curl -fsSL "$REPO/config/labwc/autostart" -o "$LABWC_DIR/autostart"
chmod +x "$LABWC_DIR/autostart"
ok "labwc config installed."

# ── 9. Auto-start labwc on login (TTY1) ───────────────────────────────────────
log "Configuring labwc auto-start on login..."
PROFILE="$HOME/.bash_profile"
MARKER="# AgenticOS: start labwc on TTY1"
if ! grep -q "$MARKER" "$PROFILE" 2>/dev/null; then
  cat >> "$PROFILE" <<'BASHEOF'

# AgenticOS: start labwc on TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  exec labwc
fi
BASHEOF
  ok "Added labwc auto-start to $PROFILE."
else
  warn "labwc auto-start already in $PROFILE, skipping."
fi

# ── 10. OpenClaw gateway auto-start via systemd user service ─────────────────
log "Setting up OpenClaw gateway systemd service..."
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/openclaw-gateway.service" <<EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
Environment=PATH=$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.npm-global/bin/openclaw gateway
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable openclaw-gateway 2>/dev/null || true
ok "OpenClaw gateway service configured."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       AgenticOS install complete! 🎉         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Make sure OpenClaw is configured (openclaw.json has your API keys)"
echo "  2. Start the OpenClaw gateway: openclaw gateway"
echo "  3. Log out and back in on TTY1 — labwc will start automatically"
echo "     (or run: labwc &)"
echo ""
echo "  Prompt bar commands:"
echo "    'restart gui'  — restart bridge + kiosk"
echo "    'restart all'  — restart gateway + bridge + kiosk"
echo ""
