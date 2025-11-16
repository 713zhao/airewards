# ai_rewards_system

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build and Run (Web)

- Build (dynamic icons):

```
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
```

- Run locally with logs (recommended):

```
flutter run -d chrome --web-port=3000
```

- Alternative headless server:

```
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=3000
```

- Note on Wasm warnings: current deps include web secure storage which triggers Wasm dry run warnings. These do not block JS builds. To silence during build:

```
flutter build web --release --no-tree-shake-icons --no-wasm-dry-run
```
