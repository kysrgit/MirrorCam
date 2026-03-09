## 2024-05-18 - Improve iOS Number Input
**Learning:** In Flutter, `TextInputType.number` often excludes the decimal point on iOS keyboards, making it impossible to input formatted numbers like IP addresses.
**Action:** Always use `TextInputType.numberWithOptions(decimal: true)` when expecting an IP address or floating-point number across platforms.
