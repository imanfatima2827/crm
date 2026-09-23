import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/lead_score.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/quick_actions.dart';
import '../../models/activity.dart';
import '../../models/lead.dart';
import '../../models/lookups.dart';
import '../../services/activity_repository.dart';
import '../../services/lead_repository.dart';
import '../../state/lookup_provider.dart';
import '../activities/activity_form_screen.dart';
import '../customers/customer_detail_screen.dart';
import '../pipeline/opportunity_detail_screen.dart';
import 'lead_form_screen.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});
  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final _repo = LeadRepository();
  final _activityRepo = ActivityRepository();
  late Future<Lead> _future;
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repo.fetchLead(widget.leadId).then((lead) async {
      _activities = await _activityRepo.fetchActivities(leadId: lead.id);
      return lead;
    });
    setState(() {});
  }

  Future<void> _convert(Lead lead) async {
    if (lead.status != 'qualified') {
      showSnack(context, 'Only Qualified leads can be converted.', error: true);
      return;
    }

    // If the lead already has an interested product, pre-fill the
    // opportunity value from that product's standard price.
    final lookups = context.read<LookupProvider>();
    final matchingProducts = lead.interestedProductId == null
        ? const <Product>[]
        : lookups.products
              .where((p) => p.id == lead.interestedProductId)
              .toList();
    final interestedProduct = matchingProducts.isEmpty
        ? null
        : matchingProducts.first;

    final titleCtrl = TextEditingController(
      text: 'Opportunity - ${lead.leadName}',
    );
    final valueCtrl = TextEditingController(
      text: interestedProduct != null
          ? interestedProduct.standardPrice.toString()
          : '',
    );
    bool createOpp = true;
    DateTime closeDate = DateTime.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: const Text('Convert Lead'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This creates a Customer record.'),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: createOpp,
                      title: const Text('Also create a sales opportunity'),
                      onChanged: (v) => setD(() {
                        createOpp = v ?? true;
                      }),
                    ),
                    if (createOpp) ...[
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Opportunity title *',
                        ),
                        validator: FieldValidators.requiredText,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Estimated value *',
                          helperText: interestedProduct != null
                              ? 'Pre-filled from ${interestedProduct.name} '
                                    '(\$${interestedProduct.standardPrice})'
                              : 'Required - must be greater than 0',
                        ),
                        validator: FieldValidators.positiveNumber,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Expected close: ${DateFormat.yMMMd().format(closeDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: closeDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (picked != null) setD(() => closeDate = picked);
                        },
                      ),
                    ],
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
                  if (createOpp && !formKey.currentState!.validate()) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Convert'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    try {
      final (customerId, opportunityId) = await _repo.convertLead(
        leadId: lead.id,
        createOpportunity: createOpp,
        opportunityTitle: titleCtrl.text.trim(),
        estimatedValue: double.tryParse(valueCtrl.text.trim()),
        expectedCloseDate: closeDate,
      );
      if (!mounted) return;
      showSnack(context, 'Lead converted successfully.');
      _load();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customerId: customerId),
        ),
      );
      if (opportunityId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                OpportunityDetailScreen(opportunityId: opportunityId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Conversion failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead Details')),
      body: FutureBuilder<Lead>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load lead.\n${snap.error}',
              onRetry: _load,
            );
          }
          final lead = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.leadName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: lead.status),
                ],
              ),
              if (lead.companyName != null && lead.companyName!.isNotEmpty)
                Text(
                  lead.companyName!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 8),
              LeadScoreBadge(
                score: LeadScore.compute(lead).score,
                tier: LeadScore.compute(lead).tier,
              ),
              const SizedBox(height: 10),
              ContactQuickActions(phone: lead.phone, email: lead.email),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Email', lead.email),
                      _row('Phone', lead.phone),
                      _row('Source', lead.sourceName),
                      _row('Interested in', lead.interestedProductName),
                      _row('Assigned to', lead.assignedToName ?? 'Unassigned'),
                      _row(
                        'Created',
                        DateFormat.yMMMd().format(lead.createdAt),
                      ),
                      if (lead.status == 'lost')
                        _row('Loss reason', lead.lostReason),
                      if (lead.notes != null && lead.notes!.isNotEmpty)
                        _row('Notes', lead.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => LeadFormScreen(existing: lead),
                        ),
                      );
                      if (updated == true) _load();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  if (lead.status == 'qualified')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () => _convert(lead),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Convert Lead'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ActivityFormScreen(leadId: lead.id),
                        ),
                      );
                      if (added == true) _load();
                    },
                    icon: const Icon(Icons.add_task_outlined),
                    label: const Text('Log Activity'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete lead?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _repo.deleteLead(lead.id);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Activity Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No activities logged yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final a in _activities)
                  Card(
                    child: ListTile(
                      title: Text(
                        a.subject,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(a.scheduledAt),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: StatusBadge(status: a.status),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
