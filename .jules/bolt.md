## 2024-05-24 - Future.wait() for ICE Candidates
**Learning:** Parallelizing the addition of ICE candidates using `Future.wait` rather than awaiting them sequentially in a `for` loop significantly speeds up WebRTC connection establishment by executing platform-bound bridge calls concurrently.
**Action:** Always use `Future.wait` when processing a buffered list of ICE candidates in Flutter WebRTC instead of sequential async iteration.
