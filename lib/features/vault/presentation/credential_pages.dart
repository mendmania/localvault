import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/adaptive_controls.dart'
    hide IconBadgeTone, TonedIconBadge;
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/vault_ui.dart';

class CredentialDetailPage extends ConsumerStatefulWidget {
  const CredentialDetailPage({required this.credentialId, super.key});

  final String credentialId;

  @override
  ConsumerState<CredentialDetailPage> createState() =>
      _CredentialDetailPageState();
}

class _CredentialDetailPageState extends ConsumerState<CredentialDetailPage> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(credentialRepositoryProvider);
    final settings = ref.watch(vaultControllerProvider).settings;
    final clipboard = ref.watch(clipboardServiceProvider);
    return FutureBuilder<Credential?>(
      future: repository.byId(widget.credentialId),
      builder: (context, snapshot) {
        final credential = snapshot.data;
        if (credential == null &&
            snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (credential == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.key_off_rounded,
              title: 'Credential not found',
              message: 'This credential may have been deleted.',
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(credential.title),
            actions: [
              IconButton(
                tooltip: 'Edit credential',
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditCredentialPage(credential: credential),
                      ),
                    )
                    .then((_) => setState(() {})),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Delete credential',
                onPressed: () =>
                    _confirmDelete(context, repository, credential),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassSurface(
                borderRadius: 28,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'credential-icon-${credential.id}',
                      child: TonedIconBadge(
                        icon: credential.isFavorite
                            ? Icons.star_rounded
                            : Icons.key_rounded,
                        tone: credential.isFavorite
                            ? IconBadgeTone.tertiary
                            : IconBadgeTone.primary,
                        size: 58,
                        iconSize: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credential.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            credential.loginIdentifier ?? 'Password hidden',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DetailFieldRow(
                label: 'Login',
                value: credential.loginIdentifier ?? 'Not set',
                icon: Icons.account_circle_rounded,
                actions: credential.loginIdentifier == null
                    ? const []
                    : [
                        IconButton(
                          tooltip: 'Copy login',
                          onPressed: () async {
                            await clipboard.copyNonSecret(
                              credential.loginIdentifier!,
                            );
                            if (context.mounted) {
                              _showCopied(context, 'Login copied.');
                            }
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
              ),
              const SizedBox(height: 12),
              DetailFieldRow(
                label: 'Password',
                value: _revealed ? credential.secret : '••••••••••••',
                icon: Icons.password_rounded,
                obscured: !_revealed,
                actions: [
                  IconButton(
                    tooltip: _revealed ? 'Hide password' : 'Reveal password',
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(
                      _revealed
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Show large',
                    onPressed: _revealed
                        ? () => showLargeValueSheet(
                            context: context,
                            title: 'Password',
                            value: credential.secret,
                          )
                        : null,
                    icon: const Icon(Icons.text_increase_rounded),
                  ),
                  IconButton.filled(
                    tooltip: 'Copy password',
                    onPressed: () async {
                      await clipboard.copySecret(
                        credential.secret,
                        settings.clipboardTimeout,
                      );
                      if (context.mounted) {
                        _showCopied(
                          context,
                          'Password copied. Clipboard clearing is best-effort.',
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              if (credential.website != null) ...[
                const SizedBox(height: 12),
                DetailFieldRow(
                  label: 'Website',
                  value: credential.website!,
                  icon: Icons.language_rounded,
                  actions: [
                    IconButton(
                      tooltip: 'Copy website',
                      onPressed: () async {
                        await clipboard.copyNonSecret(credential.website!);
                        if (context.mounted) {
                          _showCopied(context, 'Website copied.');
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ],
              if (credential.notes != null) ...[
                const SizedBox(height: 12),
                DetailFieldRow(
                  label: 'Notes',
                  value: credential.notes!,
                  icon: Icons.notes_rounded,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Clipboard clearing cannot guarantee that another app did not read copied content before it was cleared.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    dynamic repository,
    Credential credential,
  ) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Delete credential?',
      message: 'Delete "${credential.title}" from this vault.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await repository.delete(credential.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showCopied(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class AddEditCredentialPage extends ConsumerStatefulWidget {
  const AddEditCredentialPage({
    this.credential,
    this.initialPersonId,
    super.key,
  });

  final Credential? credential;
  final String? initialPersonId;

  @override
  ConsumerState<AddEditCredentialPage> createState() =>
      _AddEditCredentialPageState();
}

class _AddEditCredentialPageState extends ConsumerState<AddEditCredentialPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _login;
  late final TextEditingController _secret;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  bool _favorite = false;
  bool _showSecret = false;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final credential = widget.credential;
    _title = TextEditingController(text: credential?.title);
    _login = TextEditingController(text: credential?.loginIdentifier);
    _secret = TextEditingController(text: credential?.secret);
    _website = TextEditingController(text: credential?.website);
    _notes = TextEditingController(text: credential?.notes);
    _favorite = credential?.isFavorite ?? false;
    _personId = credential?.personId ?? widget.initialPersonId;
  }

  @override
  void dispose() {
    _title.dispose();
    _login.dispose();
    _secret.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final credential = widget.credential;
    if (credential == null) {
      return [
        _title.text,
        _login.text,
        _secret.text,
        _website.text,
        _notes.text,
      ].any((value) => value.isNotEmpty);
    }
    return _title.text != credential.title ||
        _login.text != (credential.loginIdentifier ?? '') ||
        _secret.text != credential.secret ||
        _website.text != (credential.website ?? '') ||
        _notes.text != (credential.notes ?? '') ||
        _favorite != credential.isFavorite ||
        _personId != credential.personId;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) {
      return true;
    }
    final discard = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Discard changes?',
      message: 'Unsaved credential changes will be lost.',
      cancelLabel: 'Keep editing',
      confirmLabel: 'Discard',
      destructive: true,
    );
    return discard;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final repository = ref.read(credentialRepositoryProvider);
    final existing = widget.credential;
    if (existing == null) {
      await repository.create(
        title: _title.text,
        secret: _secret.text,
        personId: _personId,
        loginIdentifier: _login.text,
        website: _website.text,
        notes: _notes.text,
        isFavorite: _favorite,
      );
    } else {
      await repository.updateCredential(
        id: existing.id,
        title: _title.text,
        secret: _secret.text,
        personId: _personId,
        loginIdentifier: _login.text,
        website: _website.text,
        notes: _notes.text,
        isFavorite: _favorite,
      );
    }
    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final peopleRepository = ref.watch(peopleRepositoryProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await _confirmDiscard() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.credential == null ? 'Add credential' : 'Edit credential',
          ),
        ),
        body: FutureBuilder<List<Person>>(
          future: peopleRepository.all(),
          builder: (context, snapshot) {
            final people = snapshot.data ?? const <Person>[];
            final effectivePersonId =
                people.any((person) => person.id == _personId)
                ? _personId
                : null;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AdaptivePickerFormField<String?>(
                        label: 'Person',
                        value: effectivePersonId,
                        options: [
                          const AdaptiveOption<String?>(
                            value: null,
                            label: 'Unassigned',
                          ),
                          ...people.map(
                            (person) => AdaptiveOption<String?>(
                              value: person.id,
                              label: person.displayName,
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _personId = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _login,
                        decoration: const InputDecoration(
                          labelText: 'Login identifier',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secret,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !_showSecret,
                        decoration: InputDecoration(
                          labelText: 'Password or secret',
                          suffixIcon: IconButton(
                            tooltip: _showSecret
                                ? 'Hide secret'
                                : 'Reveal secret',
                            onPressed: () =>
                                setState(() => _showSecret = !_showSecret),
                            icon: Icon(
                              _showSecret
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
                        controller: _website,
                        decoration: const InputDecoration(labelText: 'Website'),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _favorite,
                        onChanged: (value) => setState(() => _favorite = value),
                        title: const Text('Favorite'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: StickyActionBar(
          child: SizedBox(
            width: double.infinity,
            child: AsyncActionButton(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );
  }
}
