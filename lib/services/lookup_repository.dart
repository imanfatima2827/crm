import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/lookups.dart';
import '../models/profile.dart';

class LookupRepository {
  Future<List<LeadSource>> fetchLeadSources() async {
    final data = await sb
        .from(Tables.leadSources)
        .select()
        .eq('is_active', true)
        .order('name');
    return (data as List).map((e) => LeadSource.fromMap(e)).toList();
  }

  Future<List<OpportunityStage>> fetchStages() async {
    final data = await sb
        .from(Tables.opportunityStages)
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (data as List).map((e) => OpportunityStage.fromMap(e)).toList();
  }

  Future<List<Product>> fetchProducts({bool activeOnly = true}) async {
    var query = sb.from(Tables.products).select();
    if (activeOnly) query = query.eq('is_active', true);
    final data = await query.order('name');
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  /// All CRM users, for assignment dropdowns.
  Future<List<Profile>> fetchAssignableUsers() async {
    final data = await sb
        .from(Tables.profiles)
        .select('*, role:roles(*)')
        .eq('is_active', true)
        .order('full_name');
    return (data as List).map((e) => Profile.fromMap(e)).toList();
  }

  Future<List<RoleOption>> fetchRoles() async {
    final data = await sb.from(Tables.roles).select().order('id');
    return (data as List).map((e) => RoleOption.fromMap(e)).toList();
  }
}
