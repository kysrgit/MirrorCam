## 2024-05-24 - Parallelizing ICE candidate additions
**Learning:** Adding buffered ICE candidates sequentially via a `for` loop in `ReceiverNotifier` (`_flushPendingCandidates`) causes unnecessary connection setup delays because `addIceCandidate` makes platform-bound WebRTC calls.
**Action:** Use `Future.wait` to map and execute platform-bound WebRTC calls concurrently when flushing ICE candidates, which demonstrably reduces latency during initial connection setup.
