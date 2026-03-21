
## 2025-02-12 - WebRTC ICE & RegExp Optimization
**Learning:** During connection setup, adding buffered ICE candidates sequentially (`await _webrtcService.addIceCandidate`) delays the point at which WebRTC begins its actual transport check because it waits for each addition step to complete on the platform side before moving to the next. Also, `RegExp` object instantiation and compilation inside a string manipulation loop (like SDP modification) is costly in Dart.
**Action:** Use `Future.wait` when adding buffered ICE candidates to parallelize platform-bound async calls and reduce connection latency. Always extract `RegExp` objects outside of iteration logic (e.g., as `static final` fields) to avoid redundant object creation and compilation overhead.
