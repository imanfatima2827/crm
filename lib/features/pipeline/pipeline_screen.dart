import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../models/opportunity.dart';
import '../../services/opportunity_repository.dart';
import '../../services/realtime_service.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';
import 'opportunity_detail_screen.dart';
import 'opportunity_form_screen.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});
  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final _repo = OpportunityRepository();
  late Future<List<Opportunity>> _future;
  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchOpportunities();
    _channel = RealtimeService.watchOpportunities(_onRemoteChange);
  }

  /// Debounced so a burst of changes (e.g. bulk updates from a teammate)
  /// triggers one reload instead of many.
  void _onRemoteChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    RealtimeService.stop(_channel);
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _repo.fetchOpportunities();
  });

  Future<void> _handleDrop(
    Opportunity o,
    dynamic stage,
    AuthProvider auth,
  ) async {
    if (stage.slug == o.stageSlug) return;

    // BR-06: only Admin/Manager can move a Won deal back to an active stage.
    final currentStage = context.read<LookupProvider>().stageById(o.stageId);
    if (currentStage.isWon &&
        !stage.isWon &&
        !(auth.isAdmin || auth.isManager)) {
      showSnack(
        context,
        'Only a Manager or Admin can reopen a Won opportunity.',
        error: true,
      );
      return;
    }

    String? lossReason;
    if (stage.isLost) {
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
                maxLines: 2,
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
        stageId: stage.id,
        probability: stage.defaultProbability,
        lossReason: lossReason,
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Could not move deal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const OpportunityFormScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Deal'),
      ),
      body: FutureBuilder<List<Opportunity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || lookups.loading) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load pipeline.\n${snap.error}',
              onRetry: _reload,
            );
          }
          final opps = snap.data!;
          final stages = lookups.stages;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final stage in stages)
                  _StageColumn(
                    stage: stage,
                    deals: opps.where((o) => o.stageId == stage.id).toList(),
                    onDropDeal: (o) => _handleDrop(o, stage, auth),
                    onOpen: (o) async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OpportunityDetailScreen(opportunityId: o.id),
                        ),
                      );
                      _reload();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  final dynamic stage;
  final List<Opportunity> deals;
  final void Function(Opportunity) onDropDeal;
  final void Function(Opportunity) onOpen;
  const _StageColumn({
    required this.stage,
    required this.deals,
    required this.onDropDeal,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final total = deals.fold<double>(0, (s, o) => s + o.estimatedValue);
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      child: DragTarget<Opportunity>(
        onAcceptWithDetails: (details) => onDropDeal(details.data),
        builder: (context, candidate, rejected) {
          return Container(
            decoration: BoxDecoration(
              color: candidate.isNotEmpty
                  ? statusColor(stage.slug).withValues(alpha: 0.08)
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor(stage.slug),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stage.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${deals.length}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    _currency.format(total),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 560,
                  ),
                  child: deals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Drop deals here',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          children: [
                            for (final o in deals)
                              LongPressDraggable<Opportunity>(
                                data: o,
                                feedback: Material(
                                  color: AppColors.transparent,
                                  child: SizedBox(
                                    width: 250,
                                    child: _DealCard(o: o),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _DealCard(o: o),
                                ),
                                child: GestureDetector(
                                  onTap: () => onOpen(o),
                                  child: _DealCard(o: o),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Opportunity o;
  const _DealCard({required this.o});
  @override
  Widget build(BuildContext context) {
    final accent = statusColor(o.stageSlug ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.customerName ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currency.format(o.estimatedValue),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${o.probability}%',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (o.assignedToName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.14,
                            ),
                            child: Text(
                              o.assignedToName!.isNotEmpty
                                  ? o.assignedToName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              o.assignedToName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
