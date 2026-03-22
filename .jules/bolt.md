## 2024-03-22 - Parallelize platform-bound WebRTC calls
**Learning:** In Flutter, platform-bound WebRTC calls like `addIceCandidate` are executed sequentially by default, which can cause delays during connection setup, especially when buffering candidates.
**Action:** When applying buffered WebRTC platform calls, use `Future.wait()` on an iterable map to execute the method channel invocations concurrently, reducing connection latency.
