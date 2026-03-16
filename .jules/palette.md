## 2026-03-03 - Improved IP Address Input Keyboard
**Learning:** In Flutter, `TextInputType.number` often doesn't show a decimal point on iOS keyboards. This prevents users from easily typing an IP address in manual connection mode.
**Action:** Use `TextInputType.numberWithOptions(decimal: true)` for IP address fields so that users can input dots.
