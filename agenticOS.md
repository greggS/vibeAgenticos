# AgenticOS — Project Summary (March 2026)

## Overview
AgenticOS is a brand-new **AI-first Linux GUI** that completely replaces the legacy desktop paradigm (icons, folders, apps, menus, windows) with **exactly two living elements** from your original mockup:

- **Big blue Agents Communication Zone** (90 % of screen — a full Chromium browser where agents can freely navigate, spin local servers, inject HTML/JS/canvas, show live graphs, previews, websites — total freedom)
- **Fixed light-blue Prompt Area** at the bottom (native GTK4 bar, always visible, elegant, separate from the browser)

You simply type or speak what you want to achieve → OpenClaw agents do all the work in the background → everything (text, images, results, questions, live content) appears instantly in the big blue zone.

**Core philosophy**: No more “apps” — just tell the computer your goal. The agents handle everything transparently and conversationally.

## Key Choices We Made
- **Agent brain**: OpenClaw (already perfect, full system access, persistent agentic loops, multi-agent, skills — we never touch it)
- **Base OS**: Ubuntu 24.04.4 LTS Server (ARM64) — headless, minimal, LTS until 2029, ideal for M2 MacBook VM
- **Window manager**: labwc (tiny Wayland compositor — zero bloat, no legacy desktop)
- **Agents Zone**: Chromium kiosk (`--ozone-platform=wayland`) — real browser so agents can do anything visual
- **Prompt Area**: Native Python GTK4 bar — separate elegant element, not inside the browser
- **Terminal escape**: foot + Super+Enter hotkey (on-demand raw shell, never visible otherwise)
- **Prototype environment**: VirtualBox on M2 MacBook (3 GB RAM, 15 GB dynamic disk — super light)

## Current Status
VM installation in progress. Once ready we’ll install OpenClaw + drop the UI files + boot straight into your exact mockup.

Next steps (already prepared):
- Add local voice (Whisper.cpp)
- Dark mode
- Let agents open the terminal themselves
- Rust native client (replace Chromium + Python)
- Move to real hardware (RPi or laptop)
