import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/assignee_field.dart';
import '../../core/widgets/common.dart';
import '../../models/customer.dart';
import '../../models/opportunity.dart';
import '../../services/customer_repository.dart';
import '../../services/opportunity_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';

class OpportunityFormScreen extends StatefulWidget {
  final Opportunity? existing;
  final String? customerId;
  const OpportunityFormScreen({super.key, this.existing, this.customerId});
  @override
  State<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends State<OpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = OpportunityRepository();
  final _customerRepo = CustomerRepository();
  late TextEditingController _title, _value, _notes;
  String? _customerId;
  Customer? _lockedCustomer;
  int? _stageId;
  String? _assignedTo;
  DateTime _closeDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  List<Customer> _customerOptions = [];
  bool _loadingCustomers = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _value = TextEditingController(
      text: e != null ? e.estimatedValue.toString() : '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _customerId = e?.customerId ?? widget.customerId;
    _stageId = e?.stageId;
    _assignedTo = e?.assignedTo;
    if (e == null) {
      final auth = context.read<AuthProvider>();
      if (!(auth.isAdmin || auth.isManager)) {
        _assignedTo = auth.profile?.id;
      }
    }
    if (e != null) _closeDate = e.expectedCloseDate;
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await _customerRepo.fetchCustomers();
    if (mounted) {
      setState(() {
        _customerOptions = list;
        _loadingCustomers = false;
        if (widget.customerId != null) {
          _lockedCustomer = list
              .where((c) => c.id == widget.customerId)
              .firstOrNull;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      showSnack(context, 'Please select a customer.', error: true);
      return;
    }
    final lookups = context.read<LookupProvider>();
    if (lookups.stages.isEmpty) {
      showSnack(context, 'Pipeline stages are still loading.', error: true);
      return;
    }
    final stageId = _stageId ?? lookups.stages.first.id;
    setState(() => _saving = true);
    try {
      final o = Opportunity(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        customerId: _customerId!,
        stageId: stageId,
        estimatedValue: double.tryParse(_value.text.trim()) ?? 0,
        expectedCloseDate: _closeDate,
        assignedTo: _assignedTo,
        probability: lookups.stageById(stageId).defaultProbability,
        notes: _notes.text.trim(),
        createdAt: DateTime.now(),
      );
      if (widget.existing == null) {
        await _repo.createOpportunity(o);
      } else {
        await _repo.updateOpportunity(widget.existing!.id, o.toInsertMap());
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
  void dispose() {
    _title.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupProvider>();
    _stageId ??= lookups.stages.isNotEmpty ? lookups.stages.first.id : null;
    final stage = _stageId == null || lookups.stages.isEmpty
        ? null
        : lookups.stageById(_stageId!);
    final title = widget.existing == null
        ? 'New Opportunity'
        : 'Edit Opportunity';

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
              label: Text(_saving ? 'Saving...' : 'Save Opportunity'),
            ),
          ),
        ),
      ),
      body: _loadingCustomers
          ? const LoadingView()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _OpportunityHeader(
                    title: title,
                    stageName: stage?.name,
                    stageSlug: stage?.slug,
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    title: 'Deal profile',
                    children: [
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Deal title *',
                          prefixIcon: Icon(Icons.handshake_outlined),
                        ),
                        validator: FieldValidators.requiredText,
                      ),
                      const SizedBox(height: 14),
                      if (_lockedCustomer != null)
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          child: Text(_lockedCustomer!.customerName),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _customerId,
                          decoration: const InputDecoration(
                            labelText: 'Customer *',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          items: [
                            for (final c in _customerOptions)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.customerName),
                              ),
                          ],
                          validator: (v) => v == null ? 'Required' : null,
                          onChanged: (v) => setState(() => _customerId = v),
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _value,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimated value *',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: FieldValidators.positiveNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    title: 'Pipeline',
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text(
                          'Expected close: ${DateFormat.yMMMd().format(_closeDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _closeDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1095),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _closeDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: _stageId,
                        decoration: const InputDecoration(
                          labelText: 'Pipeline stage',
                          prefixIcon: Icon(Icons.view_kanban_outlined),
                        ),
                        items: [
                          for (final s in lookups.stages)
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ],
                        onChanged: (v) => setState(() => _stageId = v),
                      ),
                      const SizedBox(height: 14),
                      AssigneeField(
                        auth: context.watch<AuthProvider>(),
                        users: lookups.users,
                        value: _assignedTo,
                        onChanged: (v) => setState(() => _assignedTo = v),
                      ),
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
}

class _OpportunityHeader extends StatelessWidget {
  final String title;
  final String? stageName;
  final String? stageSlug;
  const _OpportunityHeader({
    required this.title,
    required this.stageName,
    required this.stageSlug,
  });

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
              Icons.handshake_outlined,
              color: AppColors.textOnPrimary,
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
                    color: AppColors.textOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stageName ?? 'Pipeline stage',
                  style: const TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (stageSlug != null)
            StatusBadge(status: stageSlug!, label: stageName),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
