# appdev2026

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


lib/
├── main.dart              ← App entry point + theme setup
├── theme_controller.dart  ← App-wide theme state (ValueNotifier)
├── auth/                  ← Authentication layer
├── models/                ← Plain data classes (DTOs)
├── controllers/           ← Thin controllers (ValueNotifier-based)
├── services/              ← Business logic + data access
├── screens/               ← UI (Views)
└── widgets/               ← Reusable UI components