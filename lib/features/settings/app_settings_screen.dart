import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../services/app_settings_repository.dart';

/// Setting keys that have a dedicated, option-based editor below instead
/// of the raw-JSON fallback editor.
const _crmSettingsKey = 'crm';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _repo = AppSettingsRepository();
  late Future<List<AppSetting>> _future;
  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAll();
  }

  void _reload() => setState(() {
    _future = _repo.fetchAll();
  });

  /// Routes to the option-based editor for known setting keys, falling
  /// back to the raw-JSON editor for anything else (e.g. custom settings
  /// an admin has added that the app has no dedicated UI for yet).
  Future<void> _openEditor(AppSetting? existing) {
    if (existing != null && existing.key == _crmSettingsKey) {
      return _editCrmSettings(existing);
    }
    return _edit(existing);
  }

  /// Option-based editor for the built-in "crm" settings: a currency
  /// picker, a bounded day stepper, and a country picker — no JSON.
  Future<void> _editCrmSettings(AppSetting existing) async {
    final currencyCodes = CommonCurrencies.values.map((e) => e.key).toSet();
    String currency = (existing.value['currency'] as String?) ?? 'USD';
    if (!currencyCodes.contains(currency)) currency = 'USD';

    int notificationDays =
        (existing.value['deal_closing_notification_days'] as num?)?.toInt() ??
        3;
    notificationDays = notificationDays.clamp(1, 30);

    final countryOptions = CommonCountries.values.toSet();
    String? country = existing.value['default_country'] as String?;
    if (country != null && !countryOptions.contains(country)) country = null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: const Text('CRM Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: [
                      for (final c in CommonCurrencies.values)
                        DropdownMenuItem(
                          value: c.key,
                          child: Text('${c.key} \u2014 ${c.value}'),
                        ),
                    ],
                    onChanged: (v) => setD(() => currency = v ?? currency),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Deal closing notification (days before)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notify the assigned rep this many days before an '
                    'opportunity\u2019s expected close date.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Decrease',
                        onPressed: notificationDays > 1
                            ? () => setD(() => notificationDays--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Text(
                          '$notificationDays ${notificationDays == 1 ? 'day' : 'days'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Increase',
                        onPressed: notificationDays < 30
                            ? () => setD(() => notificationDays++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    initialValue: country,
                    decoration: const InputDecoration(
                      labelText: 'Default country',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No default'),
                      ),
                      for (final c in CommonCountries.values)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setD(() => country = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    try {
      final value = {
        ...existing.value,
        'currency': currency,
        'deal_closing_notification_days': notificationDays,
        'default_country': country,
      };
      await _repo.upsert(
        existing.key,
        value,
        description: existing.description,
      );
      if (!mounted) return;
      showSnack(context, 'Setting saved', success: true);
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Save failed');
    }
  }

  /// Raw-JSON editor, kept as a fallback for any setting key that doesn't
  /// have a dedicated option-based editor above.
  Future<void> _edit(AppSetting? existing) async {
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final valueCtrl = TextEditingController(
      text: existing != null ? _encoder.convert(existing.value) : '{\n  \n}',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: Text(existing == null ? 'New Setting' : existing.key),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: keyCtrl,
                      enabled: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Setting key *',
                      ),
                      validator: FieldValidators.requiredText,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: valueCtrl,
                      maxLines: 6,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Value (JSON) *',
                      ),
                      validator: FieldValidators.jsonObject,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    try {
      final value = jsonDecode(valueCtrl.text) as Map<String, dynamic>;
      await _repo.upsert(
        keyCtrl.text.trim(),
        value,
        description: descCtrl.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Setting saved', success: true);
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Save failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        actions: [
          IconButton(
            tooltip: 'Add custom setting',
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(null),
          ),
        ],
      ),
      body: FutureBuilder<List<AppSetting>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load settings.\n${snap.error}',
              onRetry: _reload,
            );
          }
          final settings = snap.data!;
          if (settings.isEmpty) {
            return EmptyState(
              message: 'No app settings configured yet',
              icon: Icons.settings_outlined,
              action: OutlinedButton.icon(
                onPressed: () => _openEditor(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add a setting'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: settings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = settings[i];
              return _SettingsCard(setting: s, onEdit: () => _openEditor(s));
            },
          );
        },
      ),
    );
  }
}

/// Displays a settings record as readable fields instead of exposing its
/// storage format (the JSON object) in the main application UI.
class _SettingsCard extends StatelessWidget {
  final AppSetting setting;
  final VoidCallback onEdit;

  const _SettingsCard({required this.setting, required this.onEdit});

  String _label(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  String _valueText(Object? value) {
    if (value == null) return 'Not set';
    if (value is bool) return value ? 'Enabled' : 'Disabled';
    if (value is List) return value.isEmpty ? 'None' : value.join(', ');
    if (value is Map) {
      return value.entries
          .map(
            (entry) =>
                '${_label(entry.key.toString())}: ${_valueText(entry.value)}',
          )
          .join(', ');
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _label(setting.key),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${_label(setting.key)}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (setting.description?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(setting.description!),
            ],
            const SizedBox(height: 12),
            for (final entry in setting.value.entries) ...[
              Text(
                _label(entry.key),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                _valueText(entry.value),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Updated ${DateFormat.yMMMd().format(setting.updatedAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
