import '../core/supabase_client.dart';
import '../core/constants.dart';

class ReportRepository {
  Future<List<Map<String, dynamic>>> fetchLeadSourcePerformance() async {
    final data = await sb
        .from(Tables.vLeadSourcePerformance)
        .select()
        .order('total_leads', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchSalespersonPerformance() async {
    final data = await sb.from(Tables.vSalespersonPerformance).select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchWonLostOpportunities() async {
    final data = await sb
        .from(Tables.vWonLostOpportunities)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchLeadConversionReport() async {
    final data = await sb.from(Tables.vLeadConversionReport).select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchCustomerActivityReport() async {
    final data = await sb
        .from(Tables.vCustomerActivityReport)
        .select()
        .order('lifetime_won_value', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchOpportunityValueBreakdown() async {
    final data = await sb.from(Tables.vOpportunityValueBreakdown).select();
    return List<Map<String, dynamic>>.from(data);
  }
}
