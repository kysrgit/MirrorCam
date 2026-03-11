
## 2026-03-11 - Enhance Button Accessibility and UX in Mirror Controls
**Learning:** In Flutter, wrapping interactive icon/text combos (like the `_ControlButton` in mirror controls) with `GestureDetector` fails to provide native visual feedback and lacks screen reader context.
**Action:** Always wrap custom circular/icon buttons in `Semantics(button: true)` for screen readers. Replace `GestureDetector`+`Container` with `Material(color: Colors.transparent)` > `InkWell` > `Ink` to provide accessible visual ripple feedback while maintaining correct background color layering.
