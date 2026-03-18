## 2024-03-18 - Improve IP input UX for iOS users
**Learning:** `TextInputType.number` lacks a decimal point on iOS, making it frustrating to enter IP addresses.
**Action:** Use `TextInputType.numberWithOptions(decimal: true)` for IP input fields to ensure cross-platform usability.
