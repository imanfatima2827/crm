import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../models/opportunity.dart';
import '../../services/opportunity_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';
import 'opportunity_form_screen.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;
  const OpportunityDetailScreen({super.key, required this.opportunityId});
  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  final _repo = OpportunityRepository();
  late Future<Opportunity> _future;
  List<OpportunityProductLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repo.fetchOpportunity(widget.opportunityId).then((o) async {
      _lines = await _repo.fetchLines(o.id);
      return o;
    });
    setState(() {});
  }

  Future<void> _addLine(Opportunity o) async {
    final lookups = context.read<LookupProvider>();
    String? productId;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: const Text('Add product/service'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: productId,
                      decoration: const InputDecoration(labelText: 'Product *'),
                      items: [
                        for (final p in lookups.products)
                          DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ],
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) {
                        productId = v;
                        final p = lookups.products.firstWhere((p) => p.id == v);
                        priceCtrl.text = p.standardPrice.toString();
                        setD(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                      ),
                      validator: FieldValidators.positiveNumber,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit price *',
                      ),
                      validator: FieldValidators.nonNegativeNumber,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Discount % *',
                      ),
                      validator: FieldValidators.percentage,
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
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || productId == null) return;
    try {
      await _repo.addLine(
        OpportunityProductLine(
          id: '',
          opportunityId: o.id,
          productId: productId!,
          quantity: double.tryParse(qtyCtrl.text) ?? 1,
          unitPrice: double.tryParse(priceCtrl.text) ?? 0,
          discountPercent: double.tryParse(discountCtrl.text) ?? 0,
          lineTotal: 0,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Could not add line');
    }
  }

  Future<void> _changeStage(Opportunity o, {required bool won}) async {
    final lookups = context.read<LookupProvider>();
    final auth = context.read<AuthProvider>();
    final targetStage = lookups.stages.firstWhere(
      (s) => won ? s.isWon : s.isLost,
    );
    final currentStage = lookups.stageById(o.stageId);

    if (currentStage.isWon && !won && !(auth.isAdmin || auth.isManager)) {
      showSnack(
        context,
        'Only a Manager or Admin can reopen a Won opportunity.',
        error: true,
      );
      return;
    }

    String? lossReason;
    if (!won) {
      final formKey = GlobalKey<FormState>();
      lossReason = await showDialog<String>(
        context: context,
        builder: (context) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Loss reason'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Why was this deal lost? *',
                ),
                validator: FieldValidators.requiredText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, ctrl.text.trim());
                },
                child: const Text('Mark Lost'),
              ),
            ],
          );
        },
      );
      if (lossReason == null || lossReason.isEmpty) return;
    }

    try {
      await _repo.moveStage(
        id: o.id,
        stageId: targetStage.id,
        probability: targetStage.defaultProbability,
        lossReason: lossReason,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Could not update stage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity Details')),
      body: FutureBuilder<Opportunity>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load opportunity.\n${snap.error}',
              onRetry: _load,
            );
          }
          final o = snap.data!;
          final lineTotal = _lines.fold<double>(0, (s, l) => s + l.lineTotal);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: o.stageSlug ?? '', label: o.stageName),
                ],
              ),
              Text(
                o.customerName ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        'Estimated value',
                        _currency.format(o.estimatedValue),
                      ),
                      _row('Probability', '${o.probability}%'),
                      _row(
                        'Expected close',
                        DateFormat.yMMMd().format(o.expectedCloseDate),
                      ),
                      _row('Assigned to', o.assignedToName ?? 'Unassigned'),
                      if (o.wonAt != null)
                        _row(
                          'Won at',
                          DateFormat.yMMMd().add_jm().format(o.wonAt!),
                        ),
                      if (o.lostAt != null)
                        _row(
                          'Lost at',
                          DateFormat.yMMMd().add_jm().format(o.lostAt!),
                        ),
                      if (o.lossReason != null && o.lossReason!.isNotEmpty)
                        _row('Loss reason', o.lossReason),
                      if (o.notes != null && o.notes!.isNotEmpty)
                        _row('Notes', o.notes),
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
                          builder: (_) => OpportunityFormScreen(existing: o),
                        ),
                      );
                      if (updated == true) _load();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  if (!(o.stageSlug == 'won' || o.stageSlug == 'lost')) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () => _changeStage(o, won: true),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Mark Won'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => _changeStage(o, won: false),
                      icon: const Icon(Icons.close),
                      label: const Text('Mark Lost'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products / Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addLine(o),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No line items yet.'),
                )
              else ...[
                for (final l in _lines)
                  Card(
                    child: ListTile(
                      title: Text(l.productName ?? ''),
                      subtitle: Text(
                        '${l.quantity} \u00d7 ${_currency.format(l.unitPrice)}  (-${l.discountPercent}%)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currency.format(l.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await _repo.deleteLine(l.id);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Product line total: ${_currency.format(lineTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
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
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
