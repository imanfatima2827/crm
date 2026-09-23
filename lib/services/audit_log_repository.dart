import '../core/supabase_client.dart';
import '../core/constants.dart';

class AuditLogEntry {
  final int id;
  final String tableName;
  final String? recordId;
  final String action; // INSERT | UPDATE | DELETE
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? changedBy;
  final String? changedByName;
  final DateTime changedAt;

  AuditLogEntry({
    required this.id,
    required this.tableName,
    this.recordId,
    required this.action,
    this.oldData,
    this.newData,
    this.changedBy,
    this.changedByName,
    required this.changedAt,
  });

  factory AuditLogEntry.fromMap(
    Map<String, dynamic> map, {
    String? changedByName,
  }) {
    return AuditLogEntry(
      id: map['id'] as int,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as String?,
      action: map['action'] as String,
      oldData: map['old_data'] as Map<String, dynamic>?,
      newData: map['new_data'] as Map<String, dynamic>?,
      changedBy: map['changed_by'] as String?,
      changedByName: changedByName,
      changedAt: DateTime.parse(map['changed_at'] as String),
    );
  }
}

class AuditLogRepository {
  /// Admin-only per RLS. Optionally scoped to a single table or record.
  Future<List<AuditLogEntry>> fetchLogs({
    String? tableName,
    String? recordId,
    int limit = 100,
  }) async {
    // Do not embed `changed_by` here. Some deployments store the actor ID
    // without a database foreign key, and PostgREST then rejects the query
    // while looking for a relationship in its schema cache.
    var query = sb.from(Tables.auditLogs).select();
    if (tableName != null && tableName.isNotEmpty) {
      query = query.eq('table_name', tableName);
    }
    if (recordId != null) {
      query = query.eq('record_id', recordId);
    }
    final data = await query.order('changed_at', ascending: false).limit(limit);
    final rows = List<Map<String, dynamic>>.from(data as List);
    final actorIds = rows
        .map((row) => row['changed_by'] as String?)
        .whereType<String>()
        .toSet();
    final namesById = <String, String>{};

    if (actorIds.isNotEmpty) {
      // The audit record itself remains useful if a restrictive profile RLS
      // policy prevents resolving actor names.
      try {
        final profiles = await sb
            .from(Tables.profiles)
            .select('id, full_name')
            .inFilter('id', actorIds.toList());
        for (final profile in profiles as List) {
          final id = profile['id'] as String?;
          final name = profile['full_name'] as String?;
          if (id != null && name != null && name.isNotEmpty) {
            namesById[id] = name;
          }
        }
      } catch (_) {
        // Display the entry with "Unknown user" when profile names are hidden.
      }
    }

    return rows
        .map(
          (row) => AuditLogEntry.fromMap(
            row,
            changedByName: namesById[row['changed_by']],
          ),
        )
        .toList();
  }
}
