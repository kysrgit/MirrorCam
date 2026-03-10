## 2026-03-10 - [Accessibility & iOS Keyboard]
**Learning:** Custom controls using `GestureDetector` wrap over `Container` lack native touch ripple and are ignored by screen readers. For IP inputs, `TextInputType.number` on iOS hides the decimal point.
**Action:** Use `Semantics(button: true)` around `Material` with `InkWell` for custom buttons. Always use `TextInputType.numberWithOptions(decimal: true)` for IP/decimal inputs.
