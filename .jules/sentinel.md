## 2024-05-24 - Cross-Site WebSocket Hijacking (CSWH) in Dart HttpServer
**Vulnerability:** The signaling server upgraded HTTP requests to WebSockets without validating the Origin header, allowing malicious external websites to potentially hijack the WebSocket connection (CSWH).
**Learning:** Dart's `WebSocketTransformer.upgrade()` does not perform Origin validation automatically. The `Origin` header must be explicitly extracted from `request.headers['origin']` and validated against `request.requestedUri.host`.
**Prevention:** Always extract and validate the `Origin` header (`Uri.tryParse(origin)?.host`) against the expected host before calling `WebSocketTransformer.upgrade()`.
