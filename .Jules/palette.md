
## 2024-05-13 - [IP Address Keyboard Accessibility & GestureDetector Feedback]
**Learning:** Using `TextInputType.number` for IP address inputs on iOS hides the decimal point (.), making it impossible for users to type IPv4 addresses. Additionally, using `GestureDetector` wrapped around a `Container` provides zero visual feedback to the user and hides elements from screen readers unless explicitly wrapped in `Semantics`.
**Action:** Next time, always use `TextInputType.numberWithOptions(decimal: true)` when prompting for an IP address. Replace custom `GestureDetector` buttons with `Material` + `InkWell` to provide native ripple feedback, and always wrap custom buttons in `Semantics(button: true)`.
