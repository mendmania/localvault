import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../core/widgets/adaptive_controls.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../settings/domain/settings_models.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vaultControllerProvider);
    final controller = ref.read(vaultControllerProvider.notifier);
    final settings = state.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Lock vault',
            onPressed: controller.lock,
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeader('Security'),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric unlock'),
            subtitle: const Text(
              'Device-protected quick unlock, not recovery.',
            ),
            value: settings.biometricUnlockEnabled,
            onChanged: (value) async {
              try {
                if (value) {
                  await controller.enableBiometricUnlock();
                } else {
                  await controller.disableBiometricUnlock();
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Biometric key protection is unavailable on this device.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: const Text('Change master password'),
            subtitle: const Text('Requires the current master password.'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _ChangeMasterPasswordDialog(),
            ),
          ),
          const SectionHeader('Preferences'),
          _EnumTile<AutoLockTimeout>(
            icon: Icons.timer_rounded,
            title: 'Auto-lock timeout',
            value: settings.autoLockTimeout,
            values: AutoLockTimeout.values,
            label: (value) => value.label,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(autoLockTimeout: value),
            ),
          ),
          _DurationTile(
            value: settings.clipboardTimeout,
            onChanged: (duration) => controller.updateSettings(
              settings.copyWith(clipboardTimeout: duration),
            ),
          ),
          _EnumTile<PreferredUnitSystem>(
            icon: Icons.straighten_rounded,
            title: 'Preferred units',
            value: settings.preferredUnitSystem,
            values: PreferredUnitSystem.values,
            label: (value) => value.label,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(preferredUnitSystem: value),
            ),
          ),
          _EnumTile<AppThemeSelection>(
            icon: Icons.contrast_rounded,
            title: 'Theme',
            value: settings.themeSelection,
            values: AppThemeSelection.values,
            label: (value) => value.label,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(themeSelection: value),
            ),
          ),
          const SectionHeader('Data & backups'),
          ListTile(
            leading: const Icon(Icons.upload_file_rounded),
            title: const Text('Encrypted export'),
            subtitle: const Text('Create an encrypted .lvbackup file.'),
            onTap: () => _showBackupDialog(context, ref, export: true),
          ),
          ListTile(
            leading: const Icon(Icons.restore_page_rounded),
            title: const Text('Encrypted import'),
            subtitle: const Text('Validate backup before changing this vault.'),
            onTap: () => _showBackupDialog(context, ref, export: false),
          ),
          const SectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy explanation'),
            subtitle: const Text('Local-only storage and limitations.'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _PrivacyDialog(),
            ),
          ),
          const SectionHeader('Danger zone'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Delete vault'),
            subtitle: const Text(
              'Remove local encrypted data from this device.',
            ),
            onTap: () => _confirmDeleteVault(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool export,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _BackupPasswordDialog(export: export),
    );
  }

  Future<void> _confirmDeleteVault(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteVaultDialog(controller: controller),
    );
    controller.dispose();
    if (confirmed == true) {
      await ref.read(vaultControllerProvider.notifier).deleteVault();
    }
  }
}

class _DeleteVaultDialog extends StatefulWidget {
  const _DeleteVaultDialog({required this.controller});

  final TextEditingController controller;

  @override
  State<_DeleteVaultDialog> createState() => _DeleteVaultDialogState();
}

class _DeleteVaultDialogState extends State<_DeleteVaultDialog> {
  bool get _canDelete => widget.controller.text == 'DELETE';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete vault?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This removes the local encrypted vault and metadata from this device.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            decoration: const InputDecoration(labelText: 'Type DELETE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete vault'),
        ),
      ],
    );
  }
}

class _EnumTile<T> extends StatelessWidget {
  const _EnumTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveChoiceTile<T>(
      icon: icon,
      title: title,
      value: value,
      options: values
          .map((item) => AdaptiveOption<T>(value: item, label: label(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({required this.value, required this.onChanged});

  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = [
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
    ];
    final effectiveValue = values.contains(value) ? value : values[1];
    return AdaptiveChoiceTile<Duration>(
      icon: Icons.content_paste_off_rounded,
      title: 'Clipboard timeout',
      value: effectiveValue,
      options: values
          .map(
            (duration) => AdaptiveOption<Duration>(
              value: duration,
              label: '${duration.inSeconds} seconds',
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _BackupPasswordDialog extends ConsumerStatefulWidget {
  const _BackupPasswordDialog({required this.export});

  final bool export;

  @override
  ConsumerState<_BackupPasswordDialog> createState() =>
      _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends ConsumerState<_BackupPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!widget.export && !await _confirmRestore()) {
      return;
    }
    final controller = ref.read(vaultControllerProvider.notifier);
    final backupService = ref.read(backupServiceProvider);
    var completed = true;
    if (widget.export) {
      await controller.exportBackup(
        backupPassword: _password.text,
        backupService: backupService,
      );
    } else {
      completed = await controller.importBackup(
        backupPassword: _password.text,
        backupService: backupService,
      );
    }
    if (mounted && completed) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.export
                ? 'Encrypted backup prepared.'
                : 'Encrypted backup restored.',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmRestore() async {
    return showAdaptiveConfirmDialog(
      context: context,
      title: 'Restore backup?',
      message:
          'The selected backup will replace the current vault contents after it is authenticated.',
      confirmLabel: 'Restore',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.export ? 'Encrypted export' : 'Encrypted import'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.export
                  ? 'Use a dedicated backup password. The exported encrypted file is outside the app and must be stored safely.'
                  : 'The backup will be fully authenticated before the current vault is changed.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_show,
              decoration: InputDecoration(
                labelText: 'Backup password',
                suffixIcon: IconButton(
                  tooltip: _show ? 'Hide password' : 'Reveal password',
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(
                    _show
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (value) => value == null || value.length < 12
                  ? 'Use at least 12 characters.'
                  : null,
            ),
            if (widget.export) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                obscureText: !_show,
                decoration: const InputDecoration(
                  labelText: 'Confirm backup password',
                ),
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match.' : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AsyncActionButton(
          onPressed: _run,
          icon: Icon(
            widget.export
                ? Icons.upload_file_rounded
                : Icons.restore_page_rounded,
          ),
          child: Text(widget.export ? 'Export' : 'Import'),
        ),
      ],
    );
  }
}

class _ChangeMasterPasswordDialog extends ConsumerStatefulWidget {
  const _ChangeMasterPasswordDialog();

  @override
  ConsumerState<_ChangeMasterPasswordDialog> createState() =>
      _ChangeMasterPasswordDialogState();
}

class _ChangeMasterPasswordDialogState
    extends ConsumerState<_ChangeMasterPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(vaultControllerProvider.notifier)
        .changeMasterPasswordWithCurrentPassword(
          currentMasterPassword: _current.text,
          newMasterPassword: _next.text,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Master password changed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change master password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Pocket Memory cannot recover this password. Choose a long password you can remember.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _current,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              obscureText: !_show,
              decoration: InputDecoration(
                labelText: 'Current master password',
                suffixIcon: IconButton(
                  tooltip: _show ? 'Hide passwords' : 'Reveal passwords',
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(
                    _show
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_show,
              decoration: const InputDecoration(
                labelText: 'New master password',
              ),
              validator: (value) => value == null || value.length < 12
                  ? 'Use at least 12 characters.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_show,
              decoration: const InputDecoration(
                labelText: 'Confirm new master password',
              ),
              validator: (value) =>
                  value != _next.text ? 'Passwords do not match.' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AsyncActionButton(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PrivacyDialog extends StatelessWidget {
  const _PrivacyDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy'),
      content: const SingleChildScrollView(
        child: Text(
          'My Pocket Memory creates no account, backend, analytics stream, remote configuration, or crash-reporting connection. Records are stored in an encrypted SQLite database on this device.\n\nForgetting the master password can permanently lock the vault. Losing the device can lose the data unless an encrypted backup exists. Store only information you are authorized to retain.\n\nLimitations include rooted or jailbroken devices, compromised operating systems, malicious keyboards, accessibility malware, shoulder surfing while unlocked, weak master passwords, and the fact that iOS cannot universally prevent all screenshots.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
