import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveOption<T> {
  const AdaptiveOption({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;
}

bool usesCupertinoControls(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS;
}

Future<T?> showAdaptiveChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveOption<T>> options,
  String? message,
  String cancelLabel = 'Cancel',
}) async {
  final option = await showAdaptiveOptionSheet<T>(
    context: context,
    title: title,
    options: options,
    message: message,
    cancelLabel: cancelLabel,
  );
  return option?.value;
}

Future<AdaptiveOption<T>?> showAdaptiveOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveOption<T>> options,
  String? message,
  String cancelLabel = 'Cancel',
}) {
  if (usesCupertinoControls(context)) {
    return showCupertinoModalPopup<AdaptiveOption<T>>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        message: message == null ? null : Text(message),
        actions: options
            .map(
              (option) => CupertinoActionSheetAction(
                isDestructiveAction: option.destructive,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(option),
                child: Text(option.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }

  return showModalBottomSheet<AdaptiveOption<T>>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    if (message != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...options.map(
                (option) => ListTile(
                  leading: option.icon == null ? null : Icon(option.icon),
                  title: Text(option.label),
                  textColor: option.destructive
                      ? theme.colorScheme.error
                      : null,
                  iconColor: option.destructive
                      ? theme.colorScheme.error
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AdaptivePickerFormField<T> extends StatelessWidget {
  const AdaptivePickerFormField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String label;
  final T? value;
  final List<AdaptiveOption<T>> options;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!usesCupertinoControls(context)) {
      return DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        hint: Text(_labelForValue(value, options) ?? ''),
        validator: validator,
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      );
    }

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final selected = _labelForValue(state.value, options);
        Future<void> choose() async {
          final selectedOption = await showAdaptiveOptionSheet<T>(
            context: context,
            title: label,
            options: options,
          );
          if (selectedOption == null) {
            return;
          }
          final selectedValue = selectedOption.value;
          state.didChange(selectedValue);
          onChanged(selectedValue);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? choose : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              enabled: enabled,
            ),
            isEmpty: selected == null,
            child: Row(
              children: [
                Expanded(
                  child: Text(selected ?? '', overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdaptiveChoiceTile<T> extends StatelessWidget {
  const AdaptiveChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<AdaptiveOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _labelForValue(value, options) ?? '';
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(selected),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selectedOption = await showAdaptiveOptionSheet<T>(
          context: context,
          title: title,
          options: options,
        );
        if (selectedOption != null) {
          onChanged(selectedOption.value);
        }
      },
    );
  }
}

class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<AdaptiveOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (usesCupertinoControls(context)) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          children: {
            for (final option in options)
              option.value: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(option.label),
              ),
          },
          onValueChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: options
            .map(
              (option) => ButtonSegment<T>(
                value: option.value,
                icon: option.icon == null ? null : Icon(option.icon),
                label: Text(option.label),
              ),
            )
            .toList(),
        selected: {value},
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

Future<bool> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = usesCupertinoControls(context)
      ? await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: destructive,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )
      : await showDialog<bool>(
          context: context,
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
  return confirmed == true;
}

class AdaptiveSearchField extends StatelessWidget {
  const AdaptiveSearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (usesCupertinoControls(context)) {
      return CupertinoSearchTextField(
        controller: controller,
        placeholder: hintText,
        onChanged: onChanged,
        onSuffixTap: () {
          controller.clear();
          onChanged('');
          onClear?.call();
        },
      );
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: hintText,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

enum IconBadgeTone { primary, secondary, tertiary, error, neutral }

class TonedIconBadge extends StatelessWidget {
  const TonedIconBadge({
    required this.icon,
    this.tone = IconBadgeTone.primary,
    this.size = 40,
    this.iconSize = 22,
    super.key,
  });

  final IconData icon;
  final IconBadgeTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      IconBadgeTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      IconBadgeTone.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      IconBadgeTone.tertiary => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      IconBadgeTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      IconBadgeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

String? _labelForValue<T>(T? value, List<AdaptiveOption<T>> options) {
  for (final option in options) {
    if (option.value == value) {
      return option.label;
    }
  }
  return null;
}
