#!/usr/bin/env node
/**
 * AgenticOS WebSocket Bridge
 *
 * - Authenticates with OpenClaw gateway (port 18789)
 * - Exposes a simple WebSocket on port 18790 for the browser
 * - On each final agent response: extracts HTML, writes agents-only.html, broadcasts reload
 */

const { WebSocketServer, WebSocket } = require("ws");
const { readFileSync, writeFileSync } = require("fs");
const { homedir } = require("os");
const { join } = require("path");
const crypto = require("crypto");

const OPENCLAW_URL = "ws://127.0.0.1:18789";
const BRIDGE_PORT  = 18790;
const OPENCLAW_DIR = join(homedir(), ".openclaw");
const UI_FILE      = join(OPENCLAW_DIR, "ui-custom", "agents-content.html");

// ── HTML extraction from agent response ───────────────────────────────────
function extractHtml(text) {
  // 1. ```html ... ``` fence
  let m = /```html\s*\n([\s\S]*?)```/i.exec(text);
  if (m) return m[1].trim();

  // 2. Raw <!DOCTYPE html> ... </html>
  m = /(<(?:!DOCTYPE\s+html|html)\b[\s\S]*?<\/html>)/i.exec(text);
  if (m) return m[1].trim();

  // 3. SVG block — wrap in dark page
  m = /(<svg\b[\s\S]*?<\/svg>)/i.exec(text);
  if (m) {
    return `<!DOCTYPE html><html><head><style>
*{margin:0;padding:0}
body{background:#0a0e1a;display:flex;align-items:center;justify-content:center;min-height:100vh}
</style></head><body>${m[1]}</body></html>`;
  }

  return null;
}

function ensureCharset(html) {
  if (/<meta[^>]+charset/i.test(html)) return html;
  const tag = '<meta charset="UTF-8">';
  if (html.includes("<head>")) return html.replace("<head>", "<head>\n" + tag);
  if (html.includes("<head ")) return html.replace(/<head[^>]*>/, m => m + "\n" + tag);
  return html.replace(/(<html[^>]*>)/i, "$1\n<head>" + tag + "</head>");
}


function makeTextPage(text) {
  const esc = text.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
  return `<!DOCTYPE html><html><head><style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0e1a;color:#e8eaf0;font-family:system-ui,sans-serif;padding:44px 52px;line-height:1.75;font-size:16px}
p{margin:0 0 14px}
</style></head><body><p>${esc.replace(/\n\n/g,"</p><p>").replace(/\n/g,"<br>")}</p></body></html>`;
}

// ── Credentials ────────────────────────────────────────────────────────────
function loadCredentials() {
  const config = JSON.parse(readFileSync(join(OPENCLAW_DIR, "openclaw.json"), "utf8"));
  const device = JSON.parse(readFileSync(join(OPENCLAW_DIR, "identity", "device.json"), "utf8"));
  const auth   = JSON.parse(readFileSync(join(OPENCLAW_DIR, "identity", "device-auth.json"), "utf8"));
  return {
    deviceId:      device.deviceId,
    publicKeyPem:  device.publicKeyPem,
    privateKeyPem: device.privateKeyPem,
    deviceToken:   auth.tokens?.operator?.token ?? null,
    gatewayToken:  config?.gateway?.auth?.token ?? null,
  };
}

async function sign(privateKeyPem, message) {
  const key = crypto.createPrivateKey(privateKeyPem);
  return crypto.sign(null, Buffer.from(message), key).toString("base64url");
}

async function buildConnectParams(creds, nonce) {
  const clientId   = "openclaw-control-ui";
  const clientMode = "webchat";
  const role       = "operator";
  const scopes     = ["operator.admin", "operator.approvals", "operator.pairing"];
  const signedAt   = Date.now();
  const signingToken = creds.deviceToken ?? creds.gatewayToken ?? "";
  const authToken    = creds.gatewayToken ?? creds.deviceToken ?? "";
  const msg = ["v2", creds.deviceId, clientId, clientMode, role, scopes.join(","), String(signedAt), signingToken, nonce].join("|");
  const signature = await sign(creds.privateKeyPem, msg);
  const pubDer = crypto.createPublicKey(creds.publicKeyPem).export({ type: "spki", format: "der" });
  const pubB64 = pubDer.slice(12).toString("base64url");
  return {
    minProtocol: 3, maxProtocol: 3,
    client: { id: clientId, version: "1.0", platform: "linux", mode: clientMode, instanceId: `bridge-${Date.now()}` },
    role, scopes,
    device: { id: creds.deviceId, publicKey: pubB64, signature, signedAt, nonce },
    caps: [],
    auth: authToken ? { token: authToken } : undefined,
    userAgent: "AgenticOS/1.0 (bridge)",
    locale: "en",
  };
}

// ── Bridge ─────────────────────────────────────────────────────────────────
class Bridge {
  constructor() {
    this.creds       = loadCredentials();
    this.upstream    = null;
    this.clients     = new Set();
    this.msgQueue    = [];
    this.reconnectMs = 5000;
  }

  start() {
    this.wss = new WebSocketServer({ port: BRIDGE_PORT, host: "127.0.0.1" });
    console.log(`[bridge] Listening on ws://127.0.0.1:${BRIDGE_PORT}`);

    this.wss.on("connection", (ws) => {
      this.clients.add(ws);
      const isUp = this.upstream?.readyState === WebSocket.OPEN;
      ws.send(JSON.stringify({ type: "bridge.status", status: isUp ? "connected" : "connecting" }));
      ws.on("message", (raw) => {
        if (this.upstream?.readyState === WebSocket.OPEN) this.upstream.send(raw);
        else this.msgQueue.push(raw);
      });
      ws.on("close",  () => this.clients.delete(ws));
      ws.on("error",  (e) => console.error("[bridge] client error:", e.message));
    });

    this.connect();
  }

  broadcast(data) {
    const raw = typeof data === "string" ? data : JSON.stringify(data);
    for (const ws of this.clients) {
      if (ws.readyState === WebSocket.OPEN) ws.send(raw);
    }
  }

  handleFinalMessage(msg) {
    // Extract full text from final chat event
    const content = msg.payload?.message?.content;
    const text = Array.isArray(content)
      ? content.filter(c => c.type === "text").map(c => c.text).join("\n")
      : (typeof content === "string" ? content : "");

    if (!text) return;

    const html = extractHtml(text);
    let page;

    if (html) {
      console.log("[bridge] HTML detected in response — writing agents-content.html");
      page = ensureCharset(html);
    } else {
      console.log("[bridge] Text response — writing styled text page");
      page = ensureCharset(makeTextPage(text));
    }

    try {
      writeFileSync(UI_FILE, page, "utf8");
      // Small delay so the file is flushed before the browser reloads
      setTimeout(() => this.broadcast({ type: "reload" }), 150);
    } catch (e) {
      console.error("[bridge] Failed to write UI file:", e.message);
    }
  }

  connect() {
    console.log("[bridge] Connecting to OpenClaw...");
    this.upstream = new WebSocket(OPENCLAW_URL, { headers: { Origin: "http://127.0.0.1:18789" } });
    let reqId = 1;

    this.upstream.on("open", () => console.log("[bridge] Upstream socket open, awaiting challenge..."));

    this.upstream.on("message", async (raw) => {
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return; }

      // Auth challenge
      if (msg.type === "event" && msg.event === "connect.challenge") {
        const nonce = msg.payload?.nonce ?? "";
        try {
          const params = await buildConnectParams(this.creds, nonce);
          this.upstream.send(JSON.stringify({ type: "req", id: `init-${reqId++}`, method: "connect", params }));
          console.log(`[bridge] Sent connect (nonce=${nonce.slice(0,8)}...)`);
        } catch (e) {
          console.error("[bridge] buildConnectParams error:", e.message);
        }
        return;
      }

      if (msg.type === "res" && msg.ok && msg.id?.startsWith("init-")) {
        console.log("[bridge] OpenClaw connected!");
        this.broadcast({ type: "bridge.status", status: "connected" });
        this.reconnectMs = 5000;
        while (this.msgQueue.length) this.upstream.send(this.msgQueue.shift());
        return;
      }

      // Final message — write HTML and reload
      if (msg.type === "event" && msg.event === "chat" && msg.payload?.state === "final") {
        this.handleFinalMessage(msg);
      }

      // Forward everything to browsers
      this.broadcast(raw.toString());
    });

    this.upstream.on("close", (code, reason) => {
      console.log(`[bridge] Upstream closed: ${code} ${reason?.toString()}`);
      this.broadcast({ type: "bridge.status", status: "disconnected" });
      setTimeout(() => this.connect(), this.reconnectMs);
      this.reconnectMs = Math.min(this.reconnectMs * 2, 60000);
    });

    this.upstream.on("error", (e) => console.error("[bridge] upstream error:", e.message));
  }
}

const bridge = new Bridge();
bridge.start();
console.log("[bridge] AgenticOS bridge started. UI → ws://127.0.0.1:18790");
