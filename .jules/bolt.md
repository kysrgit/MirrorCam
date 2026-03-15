## 2024-05-18 - Extracting RegExp compilation from loops
**Learning:** Creating a `RegExp` object inside a loop during SDP optimization in Dart triggers redundant regex compilation for every line processed, unnecessarily wasting CPU cycles on a critical real-time path.
**Action:** Always extract `RegExp` objects as static final fields when used inside repetitive iteration blocks (like `sdp.split('
')`).
