import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/activity.dart';

const _activitySelect = '''
  *,
  lead:lead_id(id,lead_name),
  customer:customer_id(id,customer_name),
  opportunity:opportunity_id(id,title),
  assignee:assigned_to(id,full_name)
''';

class ActivityRepository {
  Future<List<Activity>> fetchActivities({
    String? status,
    String? assignedTo,
    String? leadId,
    String? customerId,
    String? opportunityId,
  }) async {
    var query = sb.from(Tables.activities).select(_activitySelect);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('assigned_to', assignedTo);
    }
    if (leadId != null) {
      query = query.eq('lead_id', leadId);
    }
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (opportunityId != null) {
      query = query.eq('opportunity_id', opportunityId);
    }
    final data = await query.order('scheduled_at', ascending: false);
    return (data as List).map((e) => Activity.fromMap(e)).toList();
  }

  Future<List<Activity>> fetchUpcoming({int limit = 20}) async {
    final data = await sb
        .from(Tables.vUpcomingActivities)
        .select()
        .limit(limit);
    return (data as List).map((e) => Activity.fromMap(e)).toList();
  }

  Future<List<Activity>> fetchOverdue({int limit = 50}) async {
    final data = await sb.from(Tables.vOverdueActivities).select().limit(limit);
    return (data as List).map((e) => Activity.fromMap(e)).toList();
  }

  Future<Activity> createActivity(Activity a) async {
    final data = await sb
        .from(Tables.activities)
        .insert(a.toInsertMap())
        .select(_activitySelect)
        .single();
    return Activity.fromMap(data);
  }

  Future<Activity> updateActivity(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final data = await sb
        .from(Tables.activities)
        .update(changes)
        .eq('id', id)
        .select(_activitySelect)
        .single();
    return Activity.fromMap(data);
  }

  Future<Activity> markCompleted(String id) =>
      updateActivity(id, {'status': 'completed'});

  Future<Activity> markCancelled(String id) =>
      updateActivity(id, {'status': 'cancelled'});

  /// Completed activities cannot be deleted (DB trigger blocks it too).
  Future<void> deleteActivity(String id) async {
    await sb.from(Tables.activities).delete().eq('id', id);
  }
}
