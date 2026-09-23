import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/crm_notification.dart';

class NotificationRepository {
  Future<List<CrmNotification>> fetchMyNotifications({int limit = 50}) async {
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await sb
        .from(Tables.notifications)
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => CrmNotification.fromMap(e)).toList();
  }

  Future<int> fetchUnreadCount() async {
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return 0;
    final data = await sb
        .from(Tables.notifications)
        .select('id')
        .eq('recipient_id', userId)
        .filter('read_at', 'is', null);
    return (data as List).length;
  }

  Future<void> markRead(String id) async {
    await sb
        .from(Tables.notifications)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> markAllRead() async {
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return;
    await sb
        .from(Tables.notifications)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', userId)
        .filter('read_at', 'is', null);
  }
}
