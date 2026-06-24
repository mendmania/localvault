import 'dart:io';

import 'package:flutter/services.dart';

class PlatformSecurity {
  static const _channel = MethodChannel('localvault/security');

  Future<void> enableSensitiveScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('enableSensitiveScreenProtection');
    } catch (_) {
      // Screen protection is best-effort per platform. The UI still masks data.
    }
  }

  Future<void> disableSensitiveScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('disableSensitiveScreenProtection');
    } catch (_) {
      // No sensitive values are logged.
    }
  }

  Future<void> excludeFromBackup(Iterable<String> paths) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {
        'paths': paths.toList(),
      });
    } catch (_) {
      // Documented limitation if native exclusion is unavailable.
    }
  }

  Future<Uint8List?> pickBackupFile() async {
    final bytes = await _channel.invokeMethod<Uint8List>('pickBackupFile');
    return bytes;
  }
}
