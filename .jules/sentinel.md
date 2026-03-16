
## 2026-03-16 - Prevent CSWH in Dart HttpServer WebSockets
**Vulnerability:** The Dart `HttpServer` handling WebSocket upgrades at `/ws` did not validate the `Origin` header. This allowed any website to initiate a WebSocket connection to the local signaling server, creating a Cross-Site WebSocket Hijacking (CSWH) vulnerability.
**Learning:** In Dart, `HttpHeaders` doesn't have an `originHeader` constant. The origin must be accessed via `request.headers['origin']?.first`. When checking the origin against the requested host, it is safer to parse it as a URI and compare the hosts `Uri.tryParse(origin)?.host` with `request.requestedUri.host` rather than manually splitting the host string, which breaks for IPv6 addresses.
**Prevention:** Always validate the `Origin` header before upgrading an HTTP request to a WebSocket, ensuring the origin matches the expected domain or the requested host.
