## 2024-05-24 - Unauthorized WebSocket Access Prevention
**Vulnerability:** The local WebRTC signaling server accepted WebSocket connections without authentication, allowing any device on the network that knew the IP and port to connect and access the camera stream.
**Learning:** Security features like tokens must be passed end-to-end, meaning UI elements (like QR codes and manual entry fields) need to be updated to support them. Additionally, passing secrets in URIs requires redacting them in application logs.
**Prevention:** Implement secure authentication tokens for local network services and always sanitize URIs containing credentials before logging them.
