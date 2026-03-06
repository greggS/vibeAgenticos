# OpenClaw Integration Notes

## WebSocket Protocol (v3)

OpenClaw Gateway runs on `ws://127.0.0.1:18789`.

The gateway enforces a strict handshake before accepting any client:

1. On connect, gateway sends a challenge event:
   ```json
   { "type": "event", "event": "connect.challenge", ... }
   ```

2. Client must respond with a `connect` request using allowed values:
   ```json
   {
     "type": "req",
     "id": "unique-id",
     "method": "connect",
     "params": {
       "minProtocol": 3,
       "maxProtocol": 3,
       "client": {
         "id": "webchat",        // must be an allowed constant
         "version": "1.0",
         "platform": "linux",
         "mode": "webchat"       // must be an allowed constant
       },
       "role": "operator"
     }
   }
   ```

3. Gateway also requires **device identity** — this is separate from the handshake.
   Custom clients get rejected with: `reason=device identity required`

## Known Issues

### Device Identity Required
Custom WebSocket clients (our HTML pages) are rejected by the gateway's device identity check.

**Workaround options (to investigate):**
- `openclaw config set gateway.controlUi.dangerouslyDisableDeviceAuth true`
  + `openclaw config set gateway.controlUi.allowInsecureAuth true`
  → These flags exist but may not bypass the device identity check for all client types.
- Use the official OpenClaw WebChat (`http://127.0.0.1:18789`) as the Agents Zone
  (it is pre-authorized), and keep only the Prompt Bar as our custom element.
- Inspect OpenClaw source for the correct device registration flow.

### Daemon / Systemd User Services
On fresh headless Ubuntu, `openclaw daemon install` may fail with:
  `systemctl --user is-enabled` unavailable

Fix: `sudo loginctl enable-linger $(whoami)` then re-login before running daemon commands.

## Sending Messages

Once connected, send a chat message:
```json
{ "type": "chat.send", "content": "your message here" }
```

## Agent Output Events (to listen for in the Agents Zone)

| Event type         | Description                        |
|--------------------|------------------------------------|
| `chat.delta`       | Streaming text from agent          |
| `chat.stream`      | Alternative streaming text key     |
| `thought`          | Agent reasoning / thinking         |
| `tool.call`        | Tool being executed                |
| `navigate`         | Agent wants to load a URL          |
| `inject`           | Agent injects raw HTML into zone   |
| `image`            | Agent sends an image (base64)      |
