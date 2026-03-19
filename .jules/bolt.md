# Bolt Journal

## 2024-05-24 - Initializing Journal
**Learning:** Initializing the journal for performance learnings.
**Action:** Keep track of codebase-specific performance learnings here.
## 2024-05-24 - WebRTC Parallelization & Regex Optimization
**Learning:** Buffering ICE candidates and flushing them linearly can cause a noticeable delay in connection setup. Using Future.wait allows the underlying platform calls to run concurrently, speeding up ICE negotiation. Additionally, moving RegExp compilation out of hot loops/frequent methods prevents redundant object allocation.
**Action:** Always look for opportunities to parallelize independent async platform calls during connection setup, and extract regular expressions into static final fields.
