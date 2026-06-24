# LocalVault Security Architecture

## Envelope Encryption

Vault creation generates a cryptographically random 32-byte vault key. The master password is processed with Argon2id using versioned metadata. The resulting 32-byte key-encryption key wraps the vault key with AES-256-GCM.

Persisted metadata contains:

- Crypto format version.
- KDF algorithm and parameters.
- Salt.
- AES-GCM nonce.
- Wrapped vault key.
- Authentication tag.
- KDF benchmark duration.

The master password and unwrapped vault key are never persisted. On lock, the database is closed, app state drops the database handle, and Dart references to the vault key are cleared as far as practical.

## Database Encryption

LocalVault uses Drift on `package:sqlite3` 3.x. `pubspec.yaml` requests SQLite3MultipleCiphers through native-asset hooks:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

The database factory checks that `PRAGMA cipher` exists, selects the SQLCipher-compatible cipher, applies the raw vault key before Drift reads schema information, enables foreign keys, and performs a schema read to validate the key. Cipher setup errors fail closed.

## Biometric Quick Unlock

Biometric unlock is optional and can only be enabled after a successful master-password unlock. It stores a second platform-protected representation of the vault key:

- Android uses `AndroidOptions.biometric(enforceBiometrics: true)` so the Keystore key requires user/device authentication.
- iOS uses Keychain access-control flags with `userPresence`, passcode accessibility, and Secure Enclave preference.

The master password is never stored. If biometric enrollment changes, secure storage is invalidated, or the platform cannot return the key, the app falls back to master-password unlock.

## Backup

Backups use a dedicated backup password and AES-GCM authenticated encryption. The master password is not reused automatically. Export serializes vault data in memory, encrypts it, then invokes platform sharing for the encrypted `.lvbackup` file. Import decrypts and validates the complete payload before replacing current data in a transaction.

## Platform Controls

- Android minSdk 24.
- iOS deployment target 13.0.
- Android `allowBackup=false` plus backup/data-extraction exclusions.
- iOS files excluded from backup via a platform channel.
- Android FLAG_SECURE and iOS privacy cover through `screen_protector`.
- No network feature and no `INTERNET` permission in the main manifest.
