enum AutoLockTimeout {
  immediately(Duration.zero, 'Immediately'),
  seconds30(Duration(seconds: 30), '30 seconds'),
  minute1(Duration(minutes: 1), '1 minute'),
  minutes5(Duration(minutes: 5), '5 minutes'),
  minutes15(Duration(minutes: 15), '15 minutes');

  const AutoLockTimeout(this.duration, this.label);

  final Duration duration;
  final String label;
}

enum PreferredUnitSystem {
  metric('Metric'),
  imperial('Imperial');

  const PreferredUnitSystem(this.label);

  final String label;
}

enum AppThemeSelection {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppThemeSelection(this.label);

  final String label;
}

class VaultUserSettings {
  const VaultUserSettings({
    this.autoLockTimeout = AutoLockTimeout.minute1,
    this.clipboardTimeout = const Duration(seconds: 30),
    this.preferredUnitSystem = PreferredUnitSystem.metric,
    this.themeSelection = AppThemeSelection.system,
    this.biometricUnlockEnabled = false,
  });

  final AutoLockTimeout autoLockTimeout;
  final Duration clipboardTimeout;
  final PreferredUnitSystem preferredUnitSystem;
  final AppThemeSelection themeSelection;
  final bool biometricUnlockEnabled;

  VaultUserSettings copyWith({
    AutoLockTimeout? autoLockTimeout,
    Duration? clipboardTimeout,
    PreferredUnitSystem? preferredUnitSystem,
    AppThemeSelection? themeSelection,
    bool? biometricUnlockEnabled,
  }) {
    return VaultUserSettings(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      clipboardTimeout: clipboardTimeout ?? this.clipboardTimeout,
      preferredUnitSystem: preferredUnitSystem ?? this.preferredUnitSystem,
      themeSelection: themeSelection ?? this.themeSelection,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
    );
  }
}
