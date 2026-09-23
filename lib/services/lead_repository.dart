import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/lead.dart';

const _leadSelect = '''
  *,
  lead_sources:source_id(id,name),
  interested_product:interested_product_id(id,name),
  assignee:assigned_to(id,full_name)
''';

class LeadRepository {
  Future<List<Lead>> fetchLeads({
    String? status,
    String? assignedTo,
    String? search,
  }) async {
    var query = sb.from(Tables.leads).select(_leadSelect);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('assigned_to', assignedTo);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or(
        'lead_name.ilike.%$s%,company_name.ilike.%$s%,email.ilike.%$s%,phone.ilike.%$s%',
      );
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Lead.fromMap(e)).toList();
  }

  Future<Lead> fetchLead(String id) async {
    final data = await sb
        .from(Tables.leads)
        .select(_leadSelect)
        .eq('id', id)
        .single();
    return Lead.fromMap(data);
  }

  Future<Lead> createLead(Lead lead) async {
    final data = await sb
        .from(Tables.leads)
        .insert(lead.toInsertMap())
        .select(_leadSelect)
        .single();
    return Lead.fromMap(data);
  }

  Future<Lead> updateLead(String id, Map<String, dynamic> changes) async {
    final data = await sb
        .from(Tables.leads)
        .update(changes)
        .eq('id', id)
        .select(_leadSelect)
        .single();
    return Lead.fromMap(data);
  }

  Future<void> deleteLead(String id) async {
    await sb.from(Tables.leads).delete().eq('id', id);
  }

  /// Bulk reassign or bulk status-change for a set of selected leads,
  /// used by the multi-select toolbar on the Leads list.
  Future<void> bulkUpdate(
    List<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return;
    await sb.from(Tables.leads).update(changes).inFilter('id', ids);
  }

  Future<void> bulkDelete(List<String> ids) async {
    if (ids.isEmpty) return;
    await sb.from(Tables.leads).delete().inFilter('id', ids);
  }

  /// Calls the `convert_lead` RPC (BR-03: only qualified leads convert).
  /// Returns (customerId, opportunityId?).
  Future<(String, String?)> convertLead({
    required String leadId,
    bool createOpportunity = true,
    String? opportunityTitle,
    double? estimatedValue,
    DateTime? expectedCloseDate,
  }) async {
    final result = await sb.rpc(
      'convert_lead',
      params: {
        'p_lead_id': leadId,
        'p_create_opportunity': createOpportunity,
        'p_opportunity_title': opportunityTitle,
        'p_estimated_value': estimatedValue,
        'p_expected_close_date': expectedCloseDate
            ?.toIso8601String()
            .split('T')
            .first,
      },
    );
    final row = (result as List).first as Map<String, dynamic>;
    return (row['customer_id'] as String, row['opportunity_id'] as String?);
  }
}
