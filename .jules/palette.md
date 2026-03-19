## 2026-03-19 - Semantics and InkWell for Custom Flutter Buttons
**Learning:** In Flutter, wrapping a GestureDetector around a Column (containing an icon and text) for a custom button lacks accessibility and native visual feedback.
**Action:** Replace GestureDetector with Semantics(button: true) for a11y, and use Material(color: Colors.transparent) + InkWell + Padding to provide a correct bounding box for native ripple feedback on tap.
