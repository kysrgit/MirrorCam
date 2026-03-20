## 2024-05-30 - Prevent Cross-Site WebSocket Hijacking in Signaling Server
**Vulnerability:** The local `SignalingServer` upgraded any request to `/ws` to a WebSocket, making it vulnerable to Cross-Site WebSocket Hijacking (CSWH). Malicious websites could access the local WebSocket server from a browser since WebSockets aren't bound by standard CORS policies.
**Learning:** Dart's `HttpServer` doesn't enforce Origin checks for WebSocket upgrades by default. The header `request.headers['origin']?.first` safely retrieves the Origin and must be manually verified.
**Prevention:** Always validate the `Origin` header's host against the `requestedUri.host` during WebSocket upgrades. Drop connections with `HttpStatus.forbidden` if they mismatch.
