import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/csv_export.dart';
import '../../core/lead_score.dart';
import '../../models/lead.dart';
import '../../services/lead_repository.dart';
import '../../state/lookup_provider.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';

enum _SortBy { newest, oldest, nameAZ, scoreHigh }

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});
  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final _repo = LeadRepository();
  final _searchCtrl = TextEditingController();
  String? _status;
  _SortBy _sort = _SortBy.newest;
  late Future<List<Lead>> _future;

  bool _selectionMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchLeads();
  }

  void _reload() {
    setState(() {
      _future = _repo
          .fetchLeads(status: _status, search: _searchCtrl.text)
          .then(_applySort);
    });
  }

  List<Lead> _applySort(List<Lead> leads) {
    final sorted = [...leads];
    switch (_sort) {
      case _SortBy.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortBy.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortBy.nameAZ:
        sorted.sort(
          (a, b) =>
              a.leadName.toLowerCase().compareTo(b.leadName.toLowerCase()),
        );
        break;
      case _SortBy.scoreHigh:
        sorted.sort(
          (a, b) =>
              LeadScore.compute(b).score.compareTo(LeadScore.compute(a).score),
        );
        break;
    }
    return sorted;
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selectionMode = false;
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _bulkReassign(List<Lead> allLeads) async {
    final lookups = context.read<LookupProvider>();
    String? assignee;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: Text('Reassign ${_selected.length} lead(s)'),
            content: DropdownButtonFormField<String?>(
              initialValue: assignee,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                for (final u in lookups.users)
                  DropdownMenuItem(value: u.id, child: Text(u.fullName)),
              ],
              onChanged: (v) => setD(() => assignee = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reassign'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.bulkUpdate(_selected.toList(), {'assigned_to': assignee});
      if (!mounted) return;
      showSnack(
        context,
        '${_selected.length} lead(s) reassigned',
        success: true,
      );
      _exitSelectionMode();
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Bulk reassign failed');
    }
  }

  Future<void> _bulkStatusChange() async {
    String status = 'contacted';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: Text('Change status for ${_selected.length} lead(s)'),
            content: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'New status'),
              items: [
                for (final s in LeadStatus.values)
                  if (s != 'converted')
                    DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setD(() => status = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.bulkUpdate(_selected.toList(), {'status': status});
      if (!mounted) return;
      showSnack(context, '${_selected.length} lead(s) updated', success: true);
      _exitSelectionMode();
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Bulk update failed');
    }
  }

  Future<void> _bulkDelete() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Delete ${_selected.length} lead(s)?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    try {
      await _repo.bulkDelete(_selected.toList());
      if (!mounted) return;
      showSnack(context, '${_selected.length} lead(s) deleted', success: true);
      _exitSelectionMode();
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Bulk delete failed');
    }
  }

  Future<void> _exportCsv(List<Lead> leads) async {
    try {
      await exportAndShareCsv(
        filename: 'leads.csv',
        headers: const [
          'Lead Name',
          'Company',
          'Email',
          'Phone',
          'Source',
          'Status',
          'Assigned To',
          'Score',
          'Created At',
        ],
        rows: [
          for (final l in leads)
            [
              l.leadName,
              l.companyName ?? '',
              l.email ?? '',
              l.phone ?? '',
              l.sourceName ?? '',
              l.status,
              l.assignedToName ?? 'Unassigned',
              LeadScore.compute(l).score,
              DateFormat('yyyy-MM-dd').format(l.createdAt),
            ],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Export failed');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const LeadFormScreen()),
                );
                if (created == true) _reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Lead'),
            ),
      body: FutureBuilder<List<Lead>>(
        future: _future,
        builder: (context, snap) {
          final leads = snap.data ?? [];
          return Column(
            children: [
              if (_selectionMode)
                _SelectionToolbar(
                  count: _selected.length,
                  onClose: _exitSelectionMode,
                  onReassign: () => _bulkReassign(leads),
                  onStatusChange: _bulkStatusChange,
                  onDelete: _bulkDelete,
                )
              else
                _LeadListToolbar(
                  searchCtrl: _searchCtrl,
                  leads: leads,
                  status: _status,
                  sort: _sort,
                  onReload: _reload,
                  onStatusChanged: (value) {
                    setState(() => _status = value);
                    _reload();
                  },
                  onSortChanged: (value) {
                    setState(() => _sort = value);
                    _reload();
                  },
                  onExport: () => _exportCsv(leads),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const LoadingView();
                    }
                    if (snap.hasError) {
                      return ErrorRetryView(
                        message: 'Failed to load leads.\n${snap.error}',
                        onRetry: _reload,
                      );
                    }
                    if (leads.isEmpty) {
                      return EmptyState(
                        message: 'No leads found',
                        icon: Icons.person_add_alt_outlined,
                        action: OutlinedButton.icon(
                          onPressed: () async {
                            final created = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => const LeadFormScreen(),
                                  ),
                                );
                            if (created == true) _reload();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add your first lead'),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: leads.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final l = leads[i];
                          final isSelected = _selected.contains(l.id);
                          final leadScore = LeadScore.compute(l);
                          return Card(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surfaceCard,
                            child: ListTile(
                              selected: isSelected,
                              leading: _selectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleSelected(l.id),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        l.leadName.isNotEmpty
                                            ? l.leadName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              title: Text(
                                l.leadName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (l.companyName != null &&
                                      l.companyName!.isNotEmpty)
                                    l.companyName,
                                  l.assignedToName ?? 'Unassigned',
                                ].whereType<String>().join(' \u00b7 '),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LeadScoreBadge(
                                        score: leadScore.score,
                                        tier: leadScore.tier,
                                        compact: true,
                                      ),
                                      const SizedBox(width: 6),
                                      StatusBadge(status: l.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d').format(l.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                if (_selectionMode) {
                                  _toggleSelected(l.id);
                                  return;
                                }
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LeadDetailScreen(leadId: l.id),
                                  ),
                                );
                                _reload();
                              },
                              onLongPress: () {
                                if (!_selectionMode) {
                                  _enterSelectionMode(l.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeadListToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Lead> leads;
  final String? status;
  final _SortBy sort;
  final VoidCallback onReload;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<_SortBy> onSortChanged;
  final VoidCallback onExport;

  const _LeadListToolbar({
    required this.searchCtrl,
    required this.leads,
    required this.status,
    required this.sort,
    required this.onReload,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search name, company, email, phone',
                    isDense: true,
                    suffixIcon: searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchCtrl.clear();
                              onReload();
                            },
                          ),
                  ),
                  onSubmitted: (_) => onReload(),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_SortBy>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort, color: AppColors.primary),
                initialValue: sort,
                onSelected: onSortChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _SortBy.newest,
                    child: Text('Newest first'),
                  ),
                  PopupMenuItem(
                    value: _SortBy.oldest,
                    child: Text('Oldest first'),
                  ),
                  PopupMenuItem(value: _SortBy.nameAZ, child: Text('Name A-Z')),
                  PopupMenuItem(
                    value: _SortBy.scoreHigh,
                    child: Text('Highest score'),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Export CSV',
                icon: const Icon(Icons.ios_share, color: AppColors.primary),
                onPressed: leads.isEmpty ? null : onExport,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilterChipsRow(
            options: LeadStatus.values,
            selected: status,
            allLabel: 'All statuses',
            onSelected: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

/// App-bar-style toolbar shown in place of search/filters while in
/// multi-select mode, exposing bulk actions for managers/admins.
class _SelectionToolbar extends StatelessWidget {
  final int count;
  final VoidCallback onClose;
  final VoidCallback onReassign;
  final VoidCallback onStatusChange;
  final VoidCallback onDelete;
  const _SelectionToolbar({
    required this.count,
    required this.onClose,
    required this.onReassign,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          Text(
            '$count selected',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Reassign',
            icon: const Icon(Icons.person_outline),
            onPressed: onReassign,
          ),
          IconButton(
            tooltip: 'Change status',
            icon: const Icon(Icons.flag_outlined),
            onPressed: onStatusChange,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
