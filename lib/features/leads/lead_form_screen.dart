import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/assignee_field.dart';
import '../../models/lead.dart';
import '../../services/lead_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';

class LeadFormScreen extends StatefulWidget {
  final Lead? existing;
  const LeadFormScreen({super.key, this.existing});
  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = LeadRepository();
  late TextEditingController _name;
  late TextEditingController _company;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _details;
  late TextEditingController _notes;
  late TextEditingController _lostReason;
  int? _sourceId;
  String? _productId;
  String? _assignedTo;
  String _status = 'new';
  bool _saving = false;

  bool get _isConvertedLead => widget.existing?.status == 'converted';

  List<String> get _statusOptions {
    if (_isConvertedLead) return const ['converted'];
    return LeadStatus.values.where((status) => status != 'converted').toList();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.leadName ?? '');
    _company = TextEditingController(text: e?.companyName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _details = TextEditingController(text: e?.interestDetails ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _lostReason = TextEditingController(text: e?.lostReason ?? '');
    _sourceId = e?.sourceId;
    _productId = e?.interestedProductId;
    _assignedTo = e?.assignedTo;
    _status = e?.status ?? 'new';
    if (widget.existing == null) {
      final auth = context.read<AuthProvider>();
      if (!(auth.isAdmin || auth.isManager)) {
        _assignedTo = auth.profile?.id;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _details.dispose();
    _notes.dispose();
    _lostReason.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_status == 'converted' && !_isConvertedLead) {
      showSnack(
        context,
        'Converted leads must use the Convert Lead action from a qualified lead.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final lead = Lead(
        id: widget.existing?.id ?? '',
        leadName: _name.text.trim(),
        companyName: _optional(_company),
        email: _optional(_email),
        phone: _optional(_phone),
        sourceId: _sourceId,
        interestedProductId: _productId,
        interestDetails: _optional(_details),
        assignedTo: _assignedTo,
        status: _status,
        notes: _optional(_notes),
        lostReason: _status == 'lost' ? _optional(_lostReason) : null,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (widget.existing == null) {
        await _repo.createLead(lead);
      } else {
        await _repo.updateLead(widget.existing!.id, lead.toInsertMap());
      }
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
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupProvider>();
    final auth = context.watch<AuthProvider>();
    final title = widget.existing == null ? 'New Lead' : 'Edit Lead';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
              label: Text(_saving ? 'Saving...' : 'Save Lead'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _LeadHeader(title: title, status: _status),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Lead profile',
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Lead name *',
                    prefixIcon: Icon(Icons.person_add_alt_outlined),
                  ),
                  validator: FieldValidators.requiredText,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _company,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: FieldValidators.optionalEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                  validator: FieldValidators.optionalPhone,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Interest',
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: _sourceId,
                  decoration: const InputDecoration(
                    labelText: 'Lead source',
                    prefixIcon: Icon(Icons.campaign_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-')),
                    for (final s in lookups.sources)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _sourceId = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: _productId,
                  decoration: const InputDecoration(
                    labelText: 'Interested product/service',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-')),
                    for (final p in lookups.products)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _productId = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _details,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Interest details',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Ownership',
              children: [
                AssigneeField(
                  auth: auth,
                  users: lookups.users,
                  value: _assignedTo,
                  onChanged: (v) => setState(() => _assignedTo = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: [
                    for (final s in _statusOptions)
                      DropdownMenuItem(value: s, child: Text(_labelFor(s))),
                  ],
                  onChanged: _isConvertedLead
                      ? null
                      : (v) => setState(() {
                          _status = v!;
                          if (_status != 'lost') _lostReason.clear();
                        }),
                ),
                if (_status == 'lost') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lostReason,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Lost reason *',
                      prefixIcon: Icon(Icons.feedback_outlined),
                    ),
                    validator: FieldValidators.requiredText,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Notes',
              children: [
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String value) {
    final label = value.replaceAll('_', ' ');
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _LeadHeader extends StatelessWidget {
  final String title;
  final String status;
  const _LeadHeader({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_add_alt_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: status),
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
