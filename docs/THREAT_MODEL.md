# LocalVault Threat Model

## Assets

- Credential secrets, login identifiers, notes, people, and measurements.
- Vault data-encryption key.
- Master-password wrapping metadata.
- Encrypted backup files.

## Protected Against

- Lost or stolen locked devices where normal platform device protection remains intact.
- Casual unauthorized access to the app.
- Extraction of application files from a normal non-rooted device.
- Platform backup leakage through Android backup disabling/exclusions and iOS backup-exclusion attributes.
- App-switcher preview leakage through a neutral privacy cover.
- Android screenshots through FLAG_SECURE.
- Sensitive logs by avoiding logging of passwords, decrypted records, keys, salts combined with passwords, backup passwords, or biometric outcomes containing sensitive values.
- Long-lived clipboard exposure through timed clipboard clearing after copying passwords.
- Offline guessing against copied vault files through Argon2id-wrapped vault-key metadata and authenticated encryption.

## Explicit Limitations

- Rooted or jailbroken devices.
- Compromised operating systems.
- Malicious keyboards.
- Accessibility malware.
- Shoulder surfing while the vault is unlocked.
- Weak master passwords.
- iOS cannot universally prevent all screenshots.
- Clipboard clearing is best-effort and cannot guarantee another app did not read the clipboard first.
- Biometrics are not a recovery method. The master password remains the primary unlock path.

## Security Invariants

- No backend, network client, account, synchronization service, Firebase, analytics, crash reporting, advertising SDK, telemetry, or remote configuration.
- No plaintext vault records on disk.
- No stored master password.
- No hardcoded encryption keys.
- No plaintext database fallback.
- Release Android manifest must not contain `android.permission.INTERNET`.
