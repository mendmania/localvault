import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/vault_gate.dart';

final appRouter = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const VaultGate())],
);
