## 2026-03-14 - Improve IP Address Input Keyboard on iOS
**Learning:** Using `TextInputType.number` for IP addresses works fine on Android but hides the decimal point on iOS, making it impossible to type an IP address correctly.
**Action:** Always use `TextInputType.numberWithOptions(decimal: true)` when prompting users for IP addresses to ensure accessibility on iOS keyboards.
