sealed class LocalVaultException implements Exception {
  const LocalVaultException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => safeMessage;
}

final class InvalidMasterPasswordException extends LocalVaultException {
  const InvalidMasterPasswordException()
    : super('The master password was not accepted.');
}

final class VaultCorruptedException extends LocalVaultException {
  const VaultCorruptedException()
    : super('The vault could not be opened. It may be damaged.');
}

final class CipherUnavailableException extends LocalVaultException {
  const CipherUnavailableException()
    : super('Encrypted database support is unavailable on this device.');
}

final class SecureStorageUnavailableException extends LocalVaultException {
  const SecureStorageUnavailableException()
    : super('Secure device storage is unavailable.');
}

final class BackupAuthenticationException extends LocalVaultException {
  const BackupAuthenticationException()
    : super('The backup password was not accepted.');
}

final class UnsupportedBackupVersionException extends LocalVaultException {
  const UnsupportedBackupVersionException()
    : super('This backup version is not supported.');
}

final class VaultAlreadyExistsException extends LocalVaultException {
  const VaultAlreadyExistsException()
    : super('A vault already exists on this device.');
}

final class VaultNotUnlockedException extends LocalVaultException {
  const VaultNotUnlockedException()
    : super('Unlock the vault before continuing.');
}
