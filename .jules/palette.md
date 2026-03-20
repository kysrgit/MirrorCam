## 2024-05-24 - Accessible Custom Buttons with Ripple Feedback
**Learning:** Using `GestureDetector` wrapped around a `Container` for custom buttons lacks native touch ripple feedback and accessibility features.
**Action:** Use `Semantics(button: true)` combined with `Material(color: Colors.transparent)`, `InkWell`, and `Ink` instead of `Container`. Provide an appropriate bounding `borderRadius` (e.g., `BorderRadius.circular(8)`) rather than `customBorder: const CircleBorder()` to prevent the ripple from misaligning with the rectangular layout bounds.
