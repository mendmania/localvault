# LocalVault

LocalVault is a Flutter Android/iOS MVP for a completely local encrypted personal vault.

Core promise: **No account. No cloud. No tracking. Your encrypted vault stays on this device.**

## Toolchain

- Flutter 3.44.2 stable
- Dart 3.12.2
- Android minSdk 24
- iOS deployment target 13.0

`flutter doctor -v` currently reports that Android licenses are not accepted. Run `flutter doctor --android-licenses` before relying on Android release builds.

## Architecture

- `lib/app`: app bootstrap, routing, lifecycle, theme.
- `lib/core`: crypto, encrypted Drift database, platform privacy controls, errors, utilities, shared widgets.
- `lib/features`: onboarding/authentication, vault, people, measurements, backup, settings.
- Riverpod provides dependency injection, vault lifecycle state, repository access, settings, and UI controllers.
- Widgets call repositories/controllers, not Drift or cryptography APIs directly.

## Security Design

- Envelope encryption:
  - Random 32-byte vault key.
  - Argon2id key-encryption key with versioned metadata.
  - AES-256-GCM vault-key wrapping.
  - Master password and unwrapped vault key are never persisted.
- Encrypted database:
  - Drift + `package:sqlite3` 3.x native assets.
  - SQLite3MultipleCiphers requested through `hooks.user_defines.sqlite3.source: sqlite3mc`.
  - The database setup checks `PRAGMA cipher`, applies the raw vault key before Drift schema reads, and fails closed if the cipher is unavailable.
- Privacy controls:
  - Android screenshot blocking through FLAG_SECURE via `screen_protector`.
  - iOS app-switcher cover and screen-capture awareness through `screen_protector`.
  - Local app-private storage.
  - Android backup disabled and backup/data-extraction exclusions configured.
  - iOS database and metadata paths marked excluded from backup through a platform channel.
  - Passwords are masked by default; reveal is deliberate.
  - Password clipboard clear timer defaults to 30 seconds.

See:

- `docs/THREAT_MODEL.md`
- `docs/SECURITY_ARCHITECTURE.md`

## Commands

```sh
flutter pub get
dart run build_runner build
dart format .
flutter analyze
flutter test
flutter build apk --release
flutter build ios --no-codesign
```

The Android Gradle project also contains `verifyNoReleaseInternetPermission`, and Flutter tests assert the manifest does not request `android.permission.INTERNET`.

## Backup

Encrypted export/import is versioned as `.lvbackup` data:

- Magic identifier
- Format version
- KDF identifier and parameters
- Salt
- AES-GCM nonce
- Ciphertext
- Authentication tag

The backup password is separate from the master password. Plaintext export files are never written.

## Limitations

- No recovery account exists. Forgetting the master password may permanently lock the vault.
- Losing the device may lose data unless an encrypted backup exists.
- Store only information you are authorized to retain.
- Rooted/jailbroken devices, compromised operating systems, malicious keyboards, accessibility malware, shoulder surfing while unlocked, and weak master passwords are outside the protection boundary.
- iOS cannot universally prevent all screenshots.
- Biometrics are a quick unlock path only, not a recovery method.
