## 2024-05-18 - RegExp Compilation in Loops
**Learning:** Dart's `RegExp` object creation is expensive when performed repeatedly. The codebase was re-compiling the identical `RegExp` repeatedly inside a tight loop processing SDP configuration lines, which could cause a measurable delay depending on the stream size.
**Action:** Extract repeating `RegExp` object creation into `static final` fields inside classes to avoid unnecessary compilation and allocation during iteration.
