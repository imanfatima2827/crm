import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../services/audit_log_repository.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _repo = AuditLogRepository();
  String? _table;
  late Future<List<AuditLogEntry>> _future;

  static const _tables = [
    Tables.leads,
    Tables.customers,
    Tables.opportunities,
    Tables.activities,
    Tables.products,
  ];

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchLogs();
  }

  void _reload() => setState(() {
    _future = _repo.fetchLogs(tableName: _table);
  });

  Color _actionColor(String action) {
    switch (action) {
      case 'INSERT':
        return AppColors.success;
      case 'DELETE':
        return AppColors.danger;
      default:
        return AppColors.primaryLight;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'INSERT':
        return Icons.add_circle_outline;
      case 'DELETE':
        return Icons.remove_circle_outline;
      default:
        return Icons.edit_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilterChipsRow(
              options: _tables,
              selected: _table,
              allLabel: 'All tables',
              onSelected: (v) {
                setState(() => _table = v);
                _reload();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AuditLogEntry>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorRetryView(
                    message: 'Failed to load audit log.\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                final logs = snap.data!;
                if (logs.isEmpty) {
                  return const EmptyState(
                    message: 'No changes recorded yet',
                    icon: Icons.history_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final log = logs[i];
                      return ExpansionTile(
                        leading: Icon(
                          _actionIcon(log.action),
                          color: _actionColor(log.action),
                        ),
                        title: Text(
                          '${log.action} on ${log.tableName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          '${log.changedByName ?? 'Unknown user'} \u00b7 '
                          '${DateFormat.yMMMd().add_jm().format(log.changedAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [_DiffView(log: log)],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple before/after field diff, only showing fields that actually
/// changed between old_data and new_data (or the full row for INSERT/DELETE).
class _DiffView extends StatelessWidget {
  final AuditLogEntry log;
  const _DiffView({required this.log});

  @override
  Widget build(BuildContext context) {
    final oldData = log.oldData ?? {};
    final newData = log.newData ?? {};
    final keys = {...oldData.keys, ...newData.keys}
      ..removeWhere((k) => k == 'updated_at' || k == 'created_at');

    final changedKeys = log.action == 'UPDATE'
        ? keys
              .where((k) => oldData[k].toString() != newData[k].toString())
              .toList()
        : keys.toList();
    changedKeys.sort();

    if (changedKeys.isEmpty) {
      return const Text(
        'No field-level changes to display.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in changedKeys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (log.action != 'INSERT')
                    Text(
                      '\u2212 ${oldData[key] ?? '\u2014'}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (log.action != 'DELETE')
                    Text(
                      '+ ${newData[key] ?? '\u2014'}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontFamily: 'monospace',
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
