import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/vault_ui.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vaultControllerProvider);
    final settings = state.settings;
    final credentialRepository = ref.watch(credentialRepositoryProvider);
    final peopleRepository = ref.watch(peopleRepositoryProvider);
    final measurementRepository = ref.watch(measurementRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        actions: [
          IconButton(
            tooltip: 'Lock vault',
            onPressed: () => ref.read(vaultControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Credential>>(
        stream: credentialRepository.watchAll(),
        builder: (context, credentialsSnapshot) {
          return FutureBuilder<(List<Person>, List<Measurement>)>(
            future:
                Future.wait([
                  peopleRepository.all(),
                  measurementRepository.all(),
                ]).then(
                  (values) => (
                    values[0] as List<Person>,
                    values[1] as List<Measurement>,
                  ),
                ),
            builder: (context, snapshot) {
              final credentials =
                  credentialsSnapshot.data ?? const <Credential>[];
              final people = snapshot.data?.$1 ?? const <Person>[];
              final measurements = snapshot.data?.$2 ?? const <Measurement>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                children: [
                  GlassSurface(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const TonedIconBadge(
                          icon: Icons.verified_user_rounded,
                          tone: IconBadgeTone.secondary,
                          size: 52,
                          iconSize: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local encrypted vault',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${credentials.length} credentials, ${people.length} people, ${measurements.length} measurements',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  VaultSection(
                    title: 'Access',
                    child: Column(
                      children: [
                        VaultListRow(
                          icon: Icons.timer_rounded,
                          title: 'Auto-lock',
                          subtitle: settings.autoLockTimeout.label,
                          tone: IconBadgeTone.primary,
                        ),
                        VaultListRow(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric unlock',
                          subtitle: settings.biometricUnlockEnabled
                              ? 'Enabled'
                              : 'Disabled',
                          tone: settings.biometricUnlockEnabled
                              ? IconBadgeTone.secondary
                              : IconBadgeTone.neutral,
                        ),
                        VaultListRow(
                          icon: Icons.content_paste_off_rounded,
                          title: 'Clipboard clearing',
                          subtitle:
                              '${settings.clipboardTimeout.inSeconds} seconds',
                          tone: IconBadgeTone.tertiary,
                        ),
                      ],
                    ),
                  ),
                  VaultSection(
                    title: 'Data',
                    child: Column(
                      children: const [
                        VaultListRow(
                          icon: Icons.cloud_off_rounded,
                          title: 'No cloud account',
                          subtitle: 'Records stay on this device',
                          tone: IconBadgeTone.secondary,
                        ),
                        VaultListRow(
                          icon: Icons.wifi_off_rounded,
                          title: 'No network permission',
                          subtitle: 'Release builds must stay offline',
                          tone: IconBadgeTone.secondary,
                        ),
                        VaultListRow(
                          icon: Icons.upload_file_rounded,
                          title: 'Encrypted backup',
                          subtitle: 'Export and restore from Settings',
                          tone: IconBadgeTone.tertiary,
                        ),
                      ],
                    ),
                  ),
                  VaultSection(
                    title: 'Sensitive Fields',
                    child: Column(
                      children: const [
                        VaultListRow(
                          icon: Icons.visibility_off_rounded,
                          title: 'Masked by default',
                          subtitle: 'Secrets stay hidden until revealed',
                        ),
                        VaultListRow(
                          icon: Icons.copy_rounded,
                          title: 'Timed secret copy',
                          subtitle: 'Clipboard clearing is best-effort',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
