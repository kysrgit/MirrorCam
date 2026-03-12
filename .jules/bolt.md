
## 2024-05-24 - Precompiled RegExp for SDP Optimization
**Learning:** Found an inline `RegExp(r'profile-level-id=[0-9a-fA-F]+')` inside a loop in `optimizeSdp`. Dart `RegExp` objects are expensive to compile. Compiling them inside a loop causes redundant work and memory allocation.
**Action:** Always extract `RegExp` definitions to `static final` private fields, especially when used inside string manipulation loops or frequently called methods.
