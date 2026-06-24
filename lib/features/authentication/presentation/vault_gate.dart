import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../vault/presentation/main_shell.dart';

class VaultGate extends ConsumerStatefulWidget {
  const VaultGate({super.key});

  @override
  ConsumerState<VaultGate> createState() => _VaultGateState();
}

class _VaultGateState extends ConsumerState<VaultGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(vaultControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      unawaited(
        ref.read(vaultControllerProvider.notifier).appMovedToBackground(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        unawaited(
          ref.read(vaultControllerProvider.notifier).noteUserActivity(),
        );
      },
      child: switch (state.status) {
        VaultStatus.initializing => const _SplashStatus(),
        VaultStatus.needsOnboarding => const OnboardingFlow(),
        VaultStatus.locked || VaultStatus.unlocking => const UnlockScreen(),
        VaultStatus.unlocked when state.needsBiometricChoice =>
          const OptionalBiometricSetupScreen(),
        VaultStatus.unlocked => const MainShell(),
        VaultStatus.busy => const _SplashStatus(label: 'Preparing vault...'),
        VaultStatus.error => _ErrorState(message: state.errorMessage),
      },
    );
  }
}

class _SplashStatus extends StatelessWidget {
  const _SplashStatus({this.label = 'Opening LocalVault...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 56),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(message ?? 'LocalVault could not start.'),
        ),
      ),
    );
  }
}

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _ackPassword = false;
  bool _ackDevice = false;
  bool _ackAuthorization = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!(_ackPassword && _ackDevice && _ackAuthorization)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acknowledge the local-vault risks first.'),
        ),
      );
      return;
    }
    await ref
        .read(vaultControllerProvider.notifier)
        .createVault(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('LocalVault')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: switch (_step) {
                    0 => _IntroStep(onNext: () => setState(() => _step = 1)),
                    1 => _PasswordStep(
                      passwordController: _passwordController,
                      confirmController: _confirmController,
                      onBack: () => setState(() => _step = 0),
                      onNext: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _step = 2);
                        }
                      },
                    ),
                    _ => _AcknowledgementStep(
                      ackPassword: _ackPassword,
                      ackDevice: _ackDevice,
                      ackAuthorization: _ackAuthorization,
                      onPasswordChanged: (value) =>
                          setState(() => _ackPassword = value),
                      onDeviceChanged: (value) =>
                          setState(() => _ackDevice = value),
                      onAuthorizationChanged: (value) =>
                          setState(() => _ackAuthorization = value),
                      onBack: () => setState(() => _step = 1),
                      onCreate: _create,
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('intro'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.enhanced_encryption_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'No account. No cloud. No tracking.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Your encrypted vault stays on this device. LocalVault is for information you rarely need but cannot afford to forget.',
        ),
        const SizedBox(height: 20),
        const _WarningText(),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatefulWidget {
  const _PasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('password'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create master password',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'LocalVault cannot recover this password. Use a long password you can remember.',
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: widget.passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Master password',
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Reveal password',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            final password = value ?? '';
            if (password.length < 12) {
              return 'Use at least 12 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.confirmController,
          obscureText: !_showConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm master password',
            suffixIcon: IconButton(
              tooltip: _showConfirm ? 'Hide password' : 'Reveal password',
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
              icon: Icon(
                _showConfirm
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            if (value != widget.passwordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(onPressed: widget.onBack, child: const Text('Back')),
            const Spacer(),
            FilledButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AcknowledgementStep extends StatelessWidget {
  const _AcknowledgementStep({
    required this.ackPassword,
    required this.ackDevice,
    required this.ackAuthorization,
    required this.onPasswordChanged,
    required this.onDeviceChanged,
    required this.onAuthorizationChanged,
    required this.onBack,
    required this.onCreate,
  });

  final bool ackPassword;
  final bool ackDevice;
  final bool ackAuthorization;
  final ValueChanged<bool> onPasswordChanged;
  final ValueChanged<bool> onDeviceChanged;
  final ValueChanged<bool> onAuthorizationChanged;
  final VoidCallback onBack;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('acknowledgement'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery acknowledgement',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: ackPassword,
          onChanged: (value) => onPasswordChanged(value ?? false),
          title: const Text(
            'Forgetting the master password may permanently lock the vault.',
          ),
        ),
        CheckboxListTile(
          value: ackDevice,
          onChanged: (value) => onDeviceChanged(value ?? false),
          title: const Text(
            'Losing this device may lose the data unless an encrypted backup exists.',
          ),
        ),
        CheckboxListTile(
          value: ackAuthorization,
          onChanged: (value) => onAuthorizationChanged(value ?? false),
          title: const Text(
            'I will store only information I am authorized to retain.',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const Spacer(),
            AsyncActionButton(
              onPressed: onCreate,
              icon: const Icon(Icons.lock_rounded),
              child: const Text('Create encrypted vault'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarningText extends StatelessWidget {
  const _WarningText();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'LocalVault has no recovery account. Keep the master password and encrypted backup safe.',
        ),
      ),
    );
  }
}

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _lockController;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _lockController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(vaultControllerProvider.notifier)
        .unlockWithPassword(_controller.text);
    if (mounted && ref.read(vaultControllerProvider).isUnlocked) {
      await _lockController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _lockController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: reduceMotion
                              ? 0
                              : -0.12 * _lockController.value,
                          child: Icon(
                            _lockController.value > 0.5
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unlock LocalVault',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _controller,
                      obscureText: !_show,
                      decoration: InputDecoration(
                        labelText: 'Master password',
                        errorText: state.errorMessage,
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
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                      onFieldSubmitted: (_) => _unlock(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AsyncActionButton(
                        onPressed: state.status == VaultStatus.unlocking
                            ? null
                            : _unlock,
                        icon: const Icon(Icons.lock_open_rounded),
                        child: const Text('Unlock'),
                      ),
                    ),
                    if (state.biometricAvailable) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(vaultControllerProvider.notifier)
                            .unlockWithBiometrics(),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use biometric unlock'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptionalBiometricSetupScreen extends ConsumerWidget {
  const OptionalBiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric unlock')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Optional quick unlock',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Biometric unlock stores a device-protected copy of the vault key. It is not a recovery method; the master password remains required if device authentication changes or secure storage is invalidated.',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => ref
                            .read(vaultControllerProvider.notifier)
                            .markBiometricChoiceComplete(),
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      AsyncActionButton(
                        onPressed: () async {
                          final controller = ref.read(
                            vaultControllerProvider.notifier,
                          );
                          await controller.enableBiometricUnlock();
                          controller.markBiometricChoiceComplete();
                        },
                        icon: const Icon(Icons.fingerprint_rounded),
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
