# My Pocket Memory Store Readiness

## Release Builds

Android release artifacts must be signed with a real upload or release key. Set these values in `android/key.properties`, Gradle properties, or the environment:

- `LOCALVAULT_KEYSTORE_FILE`
- `LOCALVAULT_KEYSTORE_PASSWORD`
- `LOCALVAULT_KEY_ALIAS`
- `LOCALVAULT_KEY_PASSWORD`

Run:

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
(cd android && ./gradlew :app:verifyV1ReleaseReadiness)
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Use Xcode Organizer or CI signing for the final App Store archive.

## Store Privacy Declarations

My Pocket Memory has no account, backend, telemetry, analytics, crash reporting, ads, remote configuration, or network permission. User records are processed locally and stored in the encrypted on-device vault.

For Google Play Data Safety, declare no developer collection or sharing for normal app operation. Document that encrypted backup export is a user-initiated share action and that users choose where the encrypted `.lvbackup` file goes. Provide a privacy policy even if no data is collected.

For App Store privacy labels, declare no tracking and no data collected by the developer for normal app operation. The app-level `PrivacyInfo.xcprivacy` declares no tracking, no collected data types, and no app-level required-reason APIs; bundled plugin manifests still need review during archive validation.

## Manual Release QA

- Create a vault, lock, unlock, and delete it.
- Verify biometric enable, biometric unlock, biometric disable, and fallback to master password.
- Background the app longer than the configured auto-lock timeout and confirm it locks on resume.
- Export a backup, import it into a fresh vault, reject wrong backup passwords, and confirm canceled imports do not show success.
- Check Android release manifest has no `android.permission.INTERNET`.
- Check Android backup is disabled and iOS privacy cover appears in the app switcher.
