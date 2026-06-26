# Repository Guidelines

## Project Structure & Module Organization

LocalVault is a Flutter Android/iOS app. App code lives in `lib/`: `lib/app` contains bootstrap, routing, lifecycle, and theme; `lib/core` contains shared crypto, encrypted Drift database, security utilities, errors, and widgets; `lib/features` contains feature modules such as authentication, vault, people, measurements, backup, and settings. Tests mirror this shape under `test/`, with additional security and widget coverage in `test/security` and `test/widgets`. Native platform code is in `android/` and `ios/`. Architecture and security notes are in `docs/`.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies.
- `dart run build_runner build`: regenerate Drift code such as `lib/core/database/app_database.g.dart` after schema changes.
- `dart format .`: format Dart sources.
- `flutter analyze`: run analyzer and `flutter_lints` checks.
- `flutter test`: run unit, widget, and security tests.
- `(cd android && ./gradlew :app:verifyV1ReleaseReadiness)`: verify Android release signing and no-`INTERNET` release invariants.
- `flutter build appbundle --release` and `flutter build ios --no-codesign`: create platform release builds.

## Coding Style & Naming Conventions

Use standard Dart formatting with two-space indentation. Follow `package:flutter_lints/flutter.yaml` from `analysis_options.yaml`. Prefer clear feature-scoped names and keep UI, repository/controller, Drift, and crypto responsibilities separated. Widgets should call repositories or controllers instead of reaching directly into database or cryptography APIs. Keep generated files generated; update source tables and rerun build generation.

## Testing Guidelines

Place tests beside the relevant domain area under `test/`, using `_test.dart` filenames and descriptive `test()` names. Add widget tests for user-facing flows and unit tests for crypto, database, conversion, search, and backup behavior. Preserve security regression tests, especially assertions that the main Android manifest does not request `android.permission.INTERNET`.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries, sometimes with a conventional prefix such as `chore:` and release automation markers like `[skip version bump]`. Keep commits focused and mention app version changes explicitly. Pull requests should describe the user-facing change, list validation commands run, link related issues, and include screenshots for visible UI changes.

## Security & Configuration Tips

This app is intentionally local-only: no accounts, cloud sync, tracking, or network permissions. Do not introduce plaintext export paths or persistent master-password storage. Android release signing uses `LOCALVAULT_KEYSTORE_FILE`, `LOCALVAULT_KEYSTORE_PASSWORD`, `LOCALVAULT_KEY_ALIAS`, and `LOCALVAULT_KEY_PASSWORD` through `android/key.properties`, Gradle properties, or environment variables.
