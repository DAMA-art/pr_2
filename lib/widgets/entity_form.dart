import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppFieldType { text, dropdown, multiSelect, nestedGroup }

class SelectOption {
  final int id;
  final String label;

  const SelectOption({required this.id, required this.label});
}

class AppFieldSpec {
  final AppFieldType type;
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<DropdownMenuItem<dynamic>>? items;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final String? Function(dynamic)? dropdownValidator;
  final List<SelectOption> options;
  final List<int> selectedIds;
  final ValueChanged<List<int>>? onMultiChanged;
  final String? Function(List<int>?)? multiValidator;
  final bool nestedEnabled;
  final ValueChanged<bool>? onNestedToggle;
  final List<AppFieldSpec> children;
  final String? helperText;
  final ValueChanged<String>? onTextChanged;

  const AppFieldSpec.text({
    required this.label,
    required this.controller,
    this.validator,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.onTextChanged,
  })  : type = AppFieldType.text,
        items = null,
        value = null,
        onChanged = null,
        dropdownValidator = null,
        options = const [],
        selectedIds = const [],
        onMultiChanged = null,
        multiValidator = null,
        nestedEnabled = false,
        onNestedToggle = null,
        children = const [],
        helperText = null;

  const AppFieldSpec.dropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.dropdownValidator,
    this.helperText,
  })  : type = AppFieldType.dropdown,
        controller = null,
        validator = null,
        errorText = null,
        maxLines = 1,
        maxLength = null,
        keyboardType = null,
        options = const [],
        selectedIds = const [],
        onMultiChanged = null,
        multiValidator = null,
        nestedEnabled = false,
        onNestedToggle = null,
        children = const [],
        onTextChanged = null;

  const AppFieldSpec.multiSelect({
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onMultiChanged,
    this.multiValidator,
    this.helperText,
  })  : type = AppFieldType.multiSelect,
        controller = null,
        validator = null,
        errorText = null,
        maxLines = 1,
        maxLength = null,
        keyboardType = null,
        items = null,
        value = null,
        onChanged = null,
        dropdownValidator = null,
        nestedEnabled = false,
        onNestedToggle = null,
        children = const [],
        onTextChanged = null;

  const AppFieldSpec.nestedGroup({
    required this.label,
    required this.nestedEnabled,
    required this.onNestedToggle,
    required this.children,
  })  : type = AppFieldType.nestedGroup,
        controller = null,
        validator = null,
        errorText = null,
        maxLines = 1,
        maxLength = null,
        keyboardType = null,
        items = null,
        value = null,
        onChanged = null,
        dropdownValidator = null,
        options = const [],
        selectedIds = const [],
        onMultiChanged = null,
        multiValidator = null,
        helperText = null,
        onTextChanged = null;
}

class EntityFormScaffold extends StatefulWidget {
  final String title;
  final bool loading;
  final bool saving;
  final GlobalKey<FormState> formKey;
  final List<AppFieldSpec> fields;
  final Future<bool> Function() onSave;
  final String submitLabel;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.fields,
    required this.onSave,
    this.loading = false,
    this.saving = false,
    this.submitLabel = 'Сохранить',
  });

  @override
  State<EntityFormScaffold> createState() => _EntityFormScaffoldState();
}

class _EntityFormScaffoldState extends State<EntityFormScaffold> {
  bool _dirty = false;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Вы уверены, что хотите уйти без сохранения?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Уйти')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _submit() async {
    final ok = await widget.onSave();
    if (ok && mounted) {
      setState(() => _dirty = false);
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allow = await _confirmLeave();
        if (allow && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Form(
          key: widget.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...widget.fields.map(_buildField),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.saving ? null : _submit,
                icon: widget.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(AppFieldSpec field) {
    switch (field.type) {
      case AppFieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: field.controller,
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            maxLines: field.maxLines,
            maxLength: field.maxLength,
            keyboardType: field.keyboardType,
            validator: field.validator,
            onChanged: (v) {
              _markDirty();
              field.onTextChanged?.call(v);
            },
          ),
        );
      case AppFieldType.dropdown:
        final itemValues = field.items?.map((e) => e.value).toList() ?? const [];
        final initial = itemValues.contains(field.value) ? field.value : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<dynamic>(
            key: ValueKey('${field.label}-$initial'),
            isExpanded: true,
            initialValue: initial,
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              helperText: field.helperText,
            ),
            items: field.items,
            onChanged: (v) {
              _markDirty();
              field.onChanged?.call(v);
            },
            validator: field.dropdownValidator,
          ),
        );
      case AppFieldType.multiSelect:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FormField<List<int>>(
            key: ValueKey('${field.label}-${field.selectedIds.join(',')}'),
            initialValue: field.selectedIds,
            validator: field.multiValidator,
            builder: (state) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  border: const OutlineInputBorder(),
                  errorText: state.errorText,
                  helperText: field.helperText,
                ),
                child: field.options.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Нет доступных значений'),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: field.options.map((opt) {
                          final selected = state.value!.contains(opt.id);
                          return FilterChip(
                            label: Text(opt.label),
                            selected: selected,
                            onSelected: (_) {
                              final next = [...state.value!];
                              selected ? next.remove(opt.id) : next.add(opt.id);
                              state.didChange(next);
                              _markDirty();
                              field.onMultiChanged?.call(next);
                            },
                          );
                        }).toList(),
                      ),
              );
            },
          ),
        );
      case AppFieldType.nestedGroup:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.label),
                    value: field.nestedEnabled,
                    onChanged: (v) {
                      _markDirty();
                      field.onNestedToggle?.call(v);
                    },
                  ),
                  if (field.nestedEnabled) ...field.children.map(_buildField),
                ],
              ),
            ),
          ),
        );
    }
  }
}
