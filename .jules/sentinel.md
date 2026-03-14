## 2025-02-24 - [CSWH vulnerability in local WebSocket server]
**Vulnerability:** The local WebSocket server (`SignalingServer`) accepted connections without validating the `Origin` header, allowing Cross-Site WebSocket Hijacking (CSWH) where a malicious website could access the signaling server.
**Learning:** `dart:io` `request.headers.value('origin')` can throw an exception if multiple `Origin` headers are sent, introducing a DoS risk. Using `request.headers.host?.split(':').first` fails for IPv6 addresses.
**Prevention:** Always validate `Origin` for local WebSockets. Use `request.headers['origin']?.first` safely. Use `request.requestedUri.host` to parse the host without breaking IPv6.
