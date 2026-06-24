import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../measurements/domain/measurement_models.dart';
import '../../measurements/domain/unit_conversion.dart';
import '../../vault/presentation/credential_pages.dart';

class PeopleListPage extends ConsumerWidget {
  const PeopleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(peopleRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: StreamBuilder<List<Person>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          final people = snapshot.data ?? const <Person>[];
          if (people.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No people yet',
              message:
                  'Add yourself, a parent, partner, or another person whose information you are authorized to keep.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddEditPersonPage()),
                ),
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Add person'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final person = people[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(person.displayName),
                  subtitle: Text(
                    person.relationshipLabel ?? 'No relationship label',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PersonProfilePage(personId: person.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddEditPersonPage extends ConsumerStatefulWidget {
  const AddEditPersonPage({this.person, super.key});

  final Person? person;

  @override
  ConsumerState<AddEditPersonPage> createState() => _AddEditPersonPageState();
}

class _AddEditPersonPageState extends ConsumerState<AddEditPersonPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person?.displayName);
    _relationship = TextEditingController(
      text: widget.person?.relationshipLabel,
    );
    _notes = TextEditingController(text: widget.person?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final repository = ref.read(peopleRepositoryProvider);
    final person = widget.person;
    if (person == null) {
      await repository.create(
        displayName: _name.text,
        relationshipLabel: _relationship.text,
        notes: _notes.text,
      );
    } else {
      await repository.updatePerson(
        id: person.id,
        displayName: _name.text,
        relationshipLabel: _relationship.text,
        notes: _notes.text,
      );
    }
    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? 'Add person' : 'Edit person'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _relationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship label',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AsyncActionButton(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersonProfilePage extends ConsumerWidget {
  const PersonProfilePage({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleRepository = ref.watch(peopleRepositoryProvider);
    final credentialRepository = ref.watch(credentialRepositoryProvider);
    final measurementRepository = ref.watch(measurementRepositoryProvider);
    final settings = ref.watch(vaultControllerProvider).settings;
    return FutureBuilder<Person?>(
      future: peopleRepository.byId(personId),
      builder: (context, personSnapshot) {
        final person = personSnapshot.data;
        if (person == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(person.displayName),
            actions: [
              IconButton(
                tooltip: 'Edit person',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditPersonPage(person: person),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Delete person',
                onPressed: () => _confirmDelete(context, ref, person),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (person.relationshipLabel != null)
                Text(
                  person.relationshipLabel!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (person.notes != null) ...[
                const SizedBox(height: 8),
                Text(person.notes!),
              ],
              const SectionHeader('Measurements'),
              StreamBuilder<List<Measurement>>(
                stream: measurementRepository.watchForPerson(person.id),
                builder: (context, snapshot) {
                  final measurements = snapshot.data ?? const <Measurement>[];
                  if (measurements.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditMeasurementPage(personId: person.id),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add measurement'),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...measurements.map(
                        (measurement) => _MeasurementCard(
                          measurement: measurement,
                          metric: settings.preferredUnitSystem.name == 'metric',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditMeasurementPage(personId: person.id),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add measurement'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SectionHeader('Credentials'),
              FutureBuilder<List<Credential>>(
                future: credentialRepository.forPerson(person.id),
                builder: (context, snapshot) {
                  final credentials = snapshot.data ?? const <Credential>[];
                  if (credentials.isEmpty) {
                    return OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditCredentialPage(initialPersonId: person.id),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add credential'),
                    );
                  }
                  return Column(
                    children: credentials
                        .map(
                          (credential) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.key_rounded),
                              title: Text(credential.title),
                              subtitle: const Text('Password hidden'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CredentialDetailPage(
                                    credentialId: credential.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final repository = ref.read(peopleRepositoryProvider);
    final impact = await repository.deletionImpact(person.id);
    if (!context.mounted) {
      return;
    }
    final action = await showDialog<_PersonDeleteAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${person.displayName}?'),
        content: Text(
          'This person has ${impact.credentialCount} linked credentials and ${impact.measurementCount} measurements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _PersonDeleteAction.cancel),
            child: const Text('Cancel'),
          ),
          if (impact.measurementCount == 0)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _PersonDeleteAction.unassign),
              child: const Text('Unassign credentials'),
            ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _PersonDeleteAction.deleteAll),
            child: const Text('Delete measurements'),
          ),
        ],
      ),
    );
    if (action == _PersonDeleteAction.cancel || action == null) {
      return;
    }
    await repository.deletePerson(
      id: person.id,
      unassignCredentials: true,
      deleteMeasurements: action == _PersonDeleteAction.deleteAll,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

enum _PersonDeleteAction { cancel, unassign, deleteAll }

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement, required this.metric});

  final Measurement measurement;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final template = templateFor(measurement.type);
    final title = measurement.customLabel ?? template.label;
    final value = measurement.valueKind == MeasurementValueKind.sizeLabel.name
        ? [
            if (measurement.sizeSystem != null) measurement.sizeSystem!,
            measurement.sizeLabel ?? '',
          ].join(' ').trim()
        : measurement.canonicalValueMmX100 == null
        ? 'No value'
        : formatCanonicalLength(
            measurement.canonicalValueMmX100!,
            height: measurement.type == 'height',
            metric: metric,
          );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.straighten_rounded),
        title: Text(title),
        subtitle: Text('${template.valueKind.name} • ${measurement.side}'),
        trailing: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: Text(value, key: ValueKey(value)),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditMeasurementPage(
              personId: measurement.personId,
              measurement: measurement,
            ),
          ),
        ),
      ),
    );
  }
}

class AddEditMeasurementPage extends ConsumerStatefulWidget {
  const AddEditMeasurementPage({
    required this.personId,
    this.measurement,
    super.key,
  });

  final String personId;
  final Measurement? measurement;

  @override
  ConsumerState<AddEditMeasurementPage> createState() =>
      _AddEditMeasurementPageState();
}

class _AddEditMeasurementPageState
    extends ConsumerState<AddEditMeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  late String _templateId;
  late MeasurementSide _side;
  late String _unit;
  late final TextEditingController _value;
  late final TextEditingController _feet;
  late final TextEditingController _inches;
  late final TextEditingController _customLabel;
  late final TextEditingController _sizeLabel;
  late final TextEditingController _sizeSystem;
  late final TextEditingController _notes;

  MeasurementTemplate get _template => templateFor(_templateId);

  @override
  void initState() {
    super.initState();
    final measurement = widget.measurement;
    _templateId = measurement?.type ?? measurementTemplates.first.id;
    _side = MeasurementSide.values.firstWhere(
      (side) => side.name == measurement?.side,
      orElse: () => MeasurementSide.notApplicable,
    );
    _unit = _templateId == 'height' ? 'cm' : 'cm';
    _value = TextEditingController(
      text: measurement?.canonicalValueMmX100 == null
          ? ''
          : canonicalToCentimeters(
              measurement!.canonicalValueMmX100!,
            ).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
    );
    _feet = TextEditingController();
    _inches = TextEditingController();
    _customLabel = TextEditingController(text: measurement?.customLabel);
    _sizeLabel = TextEditingController(text: measurement?.sizeLabel);
    _sizeSystem = TextEditingController(text: measurement?.sizeSystem);
    _notes = TextEditingController(text: measurement?.notes);
  }

  @override
  void dispose() {
    _value.dispose();
    _feet.dispose();
    _inches.dispose();
    _customLabel.dispose();
    _sizeLabel.dispose();
    _sizeSystem.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final repository = ref.read(measurementRepositoryProvider);
    final kind = _template.valueKind;
    final canonical = kind == MeasurementValueKind.sizeLabel
        ? null
        : parseLengthInput(
            unit: _unit,
            value: _value.text.isEmpty ? '0' : _value.text,
            feet: _feet.text,
            inches: _inches.text,
          );
    final existing = widget.measurement;
    if (existing == null) {
      await repository.create(
        personId: widget.personId,
        type: _templateId,
        customLabel: _customLabel.text,
        valueKind: kind.name,
        canonicalValueMmX100: canonical,
        sizeLabel: _sizeLabel.text,
        sizeSystem: _sizeSystem.text,
        side: _side.name,
        notes: _notes.text,
      );
    } else {
      await repository.updateMeasurement(
        id: existing.id,
        type: _templateId,
        customLabel: _customLabel.text,
        valueKind: kind.name,
        canonicalValueMmX100: canonical,
        sizeLabel: _sizeLabel.text,
        sizeSystem: _sizeSystem.text,
        side: _side.name,
        notes: _notes.text,
      );
    }
    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueKind = _template.valueKind;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.measurement == null ? 'Add measurement' : 'Edit measurement',
        ),
        actions: [
          if (widget.measurement != null)
            IconButton(
              tooltip: 'Delete measurement',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _templateId,
                  decoration: const InputDecoration(labelText: 'Measurement'),
                  items: measurementTemplates
                      .map(
                        (template) => DropdownMenuItem(
                          value: template.id,
                          child: Text(template.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _templateId = value ?? _templateId;
                  }),
                ),
                const SizedBox(height: 12),
                if (_templateId == 'custom')
                  TextFormField(
                    controller: _customLabel,
                    decoration: const InputDecoration(
                      labelText: 'Custom label',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MeasurementSide>(
                  initialValue: _side,
                  decoration: const InputDecoration(labelText: 'Side'),
                  items: MeasurementSide.values
                      .map(
                        (side) => DropdownMenuItem(
                          value: side,
                          child: Text(side.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _side = value ?? _side),
                ),
                const SizedBox(height: 12),
                if (valueKind == MeasurementValueKind.sizeLabel)
                  _SizeLabelFields(
                    sizeSystem: _sizeSystem,
                    sizeLabel: _sizeLabel,
                  )
                else
                  _LengthFields(
                    unit: _unit,
                    value: _value,
                    feet: _feet,
                    inches: _inches,
                    onUnitChanged: (value) =>
                        setState(() => _unit = value ?? _unit),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AsyncActionButton(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final measurement = widget.measurement;
    if (measurement == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete measurement?'),
        content: const Text('This measurement will be removed from the vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(measurementRepositoryProvider).delete(measurement.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _LengthFields extends StatelessWidget {
  const _LengthFields({
    required this.unit,
    required this.value,
    required this.feet,
    required this.inches,
    required this.onUnitChanged,
  });

  final String unit;
  final TextEditingController value;
  final TextEditingController feet;
  final TextEditingController inches;
  final ValueChanged<String?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: unit,
          decoration: const InputDecoration(labelText: 'Input unit'),
          items: const [
            DropdownMenuItem(value: 'cm', child: Text('Centimeters')),
            DropdownMenuItem(value: 'mm', child: Text('Millimeters')),
            DropdownMenuItem(value: 'in', child: Text('Decimal inches')),
            DropdownMenuItem(value: 'ft_in', child: Text('Feet and inches')),
          ],
          onChanged: onUnitChanged,
        ),
        const SizedBox(height: 12),
        if (unit == 'ft_in')
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: feet,
                  decoration: const InputDecoration(labelText: 'Feet'),
                  keyboardType: TextInputType.number,
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: inches,
                  decoration: const InputDecoration(labelText: 'Inches'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
              ),
            ],
          )
        else
          TextFormField(
            controller: value,
            decoration: const InputDecoration(labelText: 'Value'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
          ),
      ],
    );
  }
}

class _SizeLabelFields extends StatelessWidget {
  const _SizeLabelFields({required this.sizeSystem, required this.sizeLabel});

  final TextEditingController sizeSystem;
  final TextEditingController sizeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: sizeSystem,
            decoration: const InputDecoration(labelText: 'System'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: sizeLabel,
            decoration: const InputDecoration(labelText: 'Label'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

String? _requiredNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return double.tryParse(value) == null ? 'Enter a number' : null;
}
