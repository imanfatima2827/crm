import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../models/activity.dart';
import '../../services/activity_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';

class ActivityFormScreen extends StatefulWidget {
  final String? leadId;
  final String? customerId;
  final String? opportunityId;
  const ActivityFormScreen({
    super.key,
    this.leadId,
    this.customerId,
    this.opportunityId,
  });
  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ActivityRepository();
  late TextEditingController _subject, _description;
  String _type = 'call';
  String _priority = 'normal';
  String? _assignedTo;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController();
    _description = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      setState(() => _assignedTo = auth.profile?.id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.leadId == null &&
        widget.customerId == null &&
        widget.opportunityId == null) {
      showSnack(
        context,
        'This activity must be linked to a lead, customer or deal.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final a = Activity(
        id: '',
        leadId: widget.leadId,
        customerId: widget.customerId,
        opportunityId: widget.opportunityId,
        activityType: _type,
        subject: _subject.text.trim(),
        description: _description.text.trim(),
        scheduledAt: _scheduledAt,
        priority: _priority,
        assignedTo: _assignedTo ?? '',
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _repo.createActivity(a);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Save failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String get _linkedLabel {
    if (widget.leadId != null) return 'Linked to lead';
    if (widget.customerId != null) return 'Linked to customer';
    if (widget.opportunityId != null) return 'Linked to deal';
    return 'Choose from a lead, customer, or deal detail page';
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Log Activity')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Activity'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _ActivityHeader(linkedLabel: _linkedLabel),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Activity details',
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.event_note_outlined),
                  ),
                  items: [
                    for (final t in ActivityType.values)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subject,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.subject_outlined),
                  ),
                  validator: FieldValidators.requiredText,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Schedule',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    'Scheduled: ${DateFormat.yMMMd().add_jm().format(_scheduledAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _scheduledAt,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date == null) return;
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                    );
                    setState(
                      () => _scheduledAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? 9,
                        time?.minute ?? 0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.priority_high_outlined),
                  ),
                  items: [
                    for (final p in Priority.values)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: _assignedTo,
                  decoration: const InputDecoration(
                    labelText: 'Assigned to *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final u in lookups.users)
                      DropdownMenuItem(value: u.id, child: Text(u.fullName)),
                  ],
                  validator: FieldValidators.requiredText,
                  onChanged: (v) => setState(() => _assignedTo = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  final String linkedLabel;
  const _ActivityHeader({required this.linkedLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.overlayOnDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New activity',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  linkedLabel,
                  style: const TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title),
            ...children,
          ],
        ),
      ),
    );
  }
}
