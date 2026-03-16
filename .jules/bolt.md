## 2024-05-31 - [Extract RegExp compilation from loops]
**Learning:** Found a RegExp object being recompiled inside a loop that parses SDP lines in `WebRTCService.optimizeSdp`.
**Action:** Always extract RegExp instantiations to `static final` fields when they use constant patterns, especially when they are used inside frequently called methods or loops, to prevent redundant computation overhead.
