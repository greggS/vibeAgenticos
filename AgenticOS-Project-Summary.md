# AgenticOS — Project Summary (March 2026)

## Overview

AgenticOS is a brand-new AI-first Linux GUI that completely replaces the legacy desktop paradigm
(icons, folders, apps, menus, windows) with exactly two living elements from the original mockup:

- **Big blue Agents Communication Zone** (90% of screen) — a full Chromium browser where agents
  can freely navigate, spin local servers, inject HTML/JS/canvas, show live graphs, previews,
  websites — total freedom
- **Fixed light-blue Prompt Area** at the bottom — a separate native element (not inside the
  browser), always visible, elegant

You simply type or speak what you want to achieve → OpenClaw agents do all the work in the
background → everything (text, images, results, questions, live content) appears instantly in the
big blue zone.

**Core philosophy**: No more "apps" — just tell the computer your goal. Agents handle everything
transparently and conversationally.

## Key Architectural Choices

| Layer                  | Choice                              | Why                                                                 |
|------------------------|-------------------------------------|---------------------------------------------------------------------|
| Agent brain            | OpenClaw (self-hosted runtime)      | Already done, full system access, persistent loops, multi-agent, skills |
| Base OS                | Ubuntu 24.04.4 LTS Server (ARM64)   | Headless, minimal, LTS until 2029, ideal for M2 MacBook VM         |
| Window manager         | labwc (tiny Wayland compositor)     | Zero bloat, no legacy desktop, only our two zones + hotkey terminal |
| Agents Zone            | Chromium kiosk                      | Full browser so agents can do anything visual                       |
| Prompt Area            | Separate window (HTML or native)    | Elegant, always-on, not inside the agents browser                   |
| Terminal escape        | foot + Super+Enter hotkey           | On-demand raw shell, never visible otherwise                        |
| Prototype environment  | VirtualBox on M2 MacBook            | Safe iteration, snapshots, 3 GB RAM, 15 GB dynamic disk             |
| Integration            | OpenClaw WebSocket (port 18789)     | Official control plane, no new backend code needed                  |

## Stack

```
[Layer 0] VirtualBox VM — Ubuntu 24.04 Server ARM64 (headless)
[Layer 1] OpenClaw Gateway (ws://127.0.0.1:18789) — agent brain, persistent loops, tools, memory
[Layer 2] labwc (Wayland compositor, invisible glue)
              ├── Agents Zone: Chromium --kiosk (full browser, agents control this)
              ├── Prompt Area: separate window (light-blue, always at bottom)
              └── Terminal: foot, on-demand via Super+Enter
```

## Project Files

```
AgenticOS/
├── AgenticOS-Project-Summary.md     — this file
├── ui/
│   ├── agents-only.html             — big blue Agents Communication Zone
│   └── prompt-only.html             — separate light-blue Prompt Bar
└── config/
    ├── labwc/
    │   ├── autostart                — launches both zones + pulseaudio
    │   └── rc.xml                   — keybindings (Super+Enter = terminal)
    └── openclaw/
        └── notes.md                 — OpenClaw integration notes
```

## VM Setup (VirtualBox on M2 MacBook)

- RAM: 3 GB | CPU: 4 cores | Disk: 15 GB dynamic VDI
- Display: 128 MB video memory, 3D acceleration OFF, VMSVGA
- Network: NAT + port forwarding: Host 127.0.0.1:2222 → Guest 22 (SSH)
- OS: Ubuntu 24.04.4 LTS Server ARM64

SSH from Mac: `ssh vboxuser@127.0.0.1 -p 2222`

## Install Commands (run in VM after fresh Ubuntu install)

```bash
# Step 1: Base tools
sudo apt update && sudo apt upgrade -y && sudo apt install curl git -y

# Step 2: OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard   # choose Quickstart

# Step 3: Daemon (run after re-login if first attempt fails)
sudo loginctl enable-linger $(whoami)
# log out and back in, then:
openclaw daemon install && openclaw daemon start

# Step 4: GUI stack
sudo apt install labwc wayland-protocols wlr-randr chromium-browser foot \
                 python3-gi python3-gi-cairo gir1.2-gtk-4.0 polkitd \
                 pulseaudio -y

# Step 5: Create project files (see ui/ and config/ folders)
mkdir -p ~/.openclaw/ui-custom ~/.config/labwc
# copy agents-only.html and prompt-only.html to ~/.openclaw/ui-custom/
# copy config/labwc/* to ~/.config/labwc/

# Step 6: Launch
cd ~/.openclaw/ui-custom && python3 -m http.server 8080 &
WLR_RENDERER=pixman labwc &
```

## Current Status (March 2026)

- First prototype booted in VirtualBox
- Two separate zones visible: big blue Agents Zone + light-blue Prompt Bar
- OpenClaw WebSocket connection: partially working
  - Known blocker: OpenClaw requires "device identity" for custom WebSocket clients
  - Workaround in progress: need to find the correct handshake or use the official WebChat
    as the agents zone while keeping the separate prompt bar

## Open Issues / TODOs

- [ ] Resolve OpenClaw WebSocket device identity requirement for custom clients
- [ ] Fix labwc daemon auto-start on headless boot (loginctl linger issue)
- [ ] Decide final Prompt Area implementation: HTML window vs native GTK4 vs Rust
- [ ] GTK4 Python prompt bar: `set_keep_above` / `set_always_on_top` not available — find correct GTK4 API
- [ ] Add local voice input (Whisper.cpp via OpenClaw skill)
- [ ] Dark mode variant
- [ ] Make agents able to open the terminal themselves via tool call
- [ ] Rust native shell (long term) to replace labwc + Chromium

## Next Steps

1. Investigate OpenClaw WebSocket protocol docs / source to find valid device identity approach
2. Test using the official OpenClaw WebChat UI as the agents zone (it handles auth) + separate prompt bar
3. Polish the two-zone layout and test real agent prompts
4. Document first working agent interaction

## Research Notes

- No one else has shipped this exact combo (verified March 2026)
- ClawX exists but is just an Electron app on top of normal desktops — not what we're building
- AIOS, TensorAgent OS, Bytebot, AgentDesk — all either cloud-streamed or apps on legacy DEs
- labwc: https://labwc.github.io/ (v0.9.5 as of March 2026, actively maintained)
