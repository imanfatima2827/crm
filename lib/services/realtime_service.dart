import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/constants.dart';

/// Thin wrapper around Supabase Realtime so screens don't repeat the
/// channel-naming/subscribe/cleanup boilerplate. Each call returns the
/// [RealtimeChannel] so the caller can remove it in `dispose()`.
class RealtimeService {
  /// Fires [onChange] whenever a row in [table] is inserted, updated, or
  /// deleted. Pass [filterColumn]/[filterValue] to scope to e.g. a single
  /// user's notifications.
  static RealtimeChannel watchTable(
    String table, {
    required void Function() onChange,
    String? filterColumn,
    String? filterValue,
    String? channelSuffix,
  }) {
    final channel = sb.channel(
      'public:$table:${channelSuffix ?? filterValue ?? 'all'}',
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: (filterColumn != null && filterValue != null)
          ? PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: filterColumn,
              value: filterValue,
            )
          : null,
      callback: (payload) => onChange(),
    );
    channel.subscribe();
    return channel;
  }

  static RealtimeChannel watchNotifications(
    String userId,
    void Function() onChange,
  ) {
    return watchTable(
      Tables.notifications,
      filterColumn: 'recipient_id',
      filterValue: userId,
      onChange: onChange,
      channelSuffix: 'notif-$userId',
    );
  }

  static RealtimeChannel watchOpportunities(void Function() onChange) {
    return watchTable(
      Tables.opportunities,
      onChange: onChange,
      channelSuffix: 'pipeline',
    );
  }

  static void stop(RealtimeChannel? channel) {
    if (channel != null) sb.removeChannel(channel);
  }
}
