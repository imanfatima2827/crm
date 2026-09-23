import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/profile.dart';

class UserRepository {
  Future<List<Profile>> fetchAllUsers() async {
    final data = await sb
        .from(Tables.profiles)
        .select('*, role:roles(*)')
        .order('full_name');
    return (data as List).map((e) => Profile.fromMap(e)).toList();
  }

  /// Admin-only: change role, manager, active flag via the
  /// `admin_set_user_access` RPC (RLS restricts this server-side too).
  Future<void> setUserAccess({
    required String userId,
    required String roleSlug,
    String? managerId,
    bool isActive = true,
  }) async {
    await sb.rpc(
      'admin_set_user_access',
      params: {
        'p_user_id': userId,
        'p_role_slug': roleSlug,
        'p_manager_id': managerId,
        'p_is_active': isActive,
      },
    );
  }

  Future<void> updateMyProfile(Map<String, dynamic> changes) async {
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return;
    await sb.from(Tables.profiles).update(changes).eq('id', userId);
  }
}
