## 2024-05-24 - Extract RegExp from loop in WebRTCService
**Learning:** Compiling `RegExp` objects inside a loop (or frequently called methods) in Dart introduces unnecessary CPU overhead and garbage collection pressure.
**Action:** Extract `RegExp` definitions to `static final` fields at the class level so they are compiled only once.
