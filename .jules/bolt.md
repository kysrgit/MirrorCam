## 2024-05-24 - [Dart RegExp Compilation Performance]
**Learning:** Dart's RegExp object compilation can be an expensive operation. Instantiating `RegExp` objects inside frequently called loops or high-throughput parsing functions (like parsing SDP strings in WebRTC negotiations) leads to unnecessary overhead and object creation.
**Action:** Always extract frequently used `RegExp` objects and define them as `static final` fields within the class. This ensures the pattern is compiled exactly once, avoiding redundant processing and improving efficiency in string-heavy operations.
