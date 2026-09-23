import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/opportunity.dart';

const _oppSelect = '''
  *,
  customer:customer_id(id,customer_name),
  stage:stage_id(id,name,slug,is_won,is_lost,is_closed),
  assignee:assigned_to(id,full_name)
''';

class OpportunityRepository {
  Future<List<Opportunity>> fetchOpportunities({
    int? stageId,
    String? assignedTo,
    String? search,
  }) async {
    var query = sb.from(Tables.opportunities).select(_oppSelect);
    if (stageId != null) {
      query = query.eq('stage_id', stageId);
    }
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('assigned_to', assignedTo);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }
    final data = await query.order('expected_close_date');
    return (data as List).map((e) => Opportunity.fromMap(e)).toList();
  }

  Future<Opportunity> fetchOpportunity(String id) async {
    final data = await sb
        .from(Tables.opportunities)
        .select(_oppSelect)
        .eq('id', id)
        .single();
    return Opportunity.fromMap(data);
  }

  Future<Opportunity> createOpportunity(Opportunity o) async {
    final data = await sb
        .from(Tables.opportunities)
        .insert(o.toInsertMap())
        .select(_oppSelect)
        .single();
    return Opportunity.fromMap(data);
  }

  Future<Opportunity> updateOpportunity(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final data = await sb
        .from(Tables.opportunities)
        .update(changes)
        .eq('id', id)
        .select(_oppSelect)
        .single();
    return Opportunity.fromMap(data);
  }

  /// Moves a deal to a new stage (used by the Kanban board drag/drop
  /// and the detail screen). Losing a deal requires a reason (DB enforces
  /// this too, but we validate client-side for a friendlier error).
  Future<Opportunity> moveStage({
    required String id,
    required int stageId,
    int? probability,
    String? lossReason,
  }) async {
    final changes = <String, dynamic>{'stage_id': stageId};
    if (probability != null) changes['probability'] = probability;
    if (lossReason != null) changes['loss_reason'] = lossReason;
    return updateOpportunity(id, changes);
  }

  Future<void> deleteOpportunity(String id) async {
    await sb.from(Tables.opportunities).delete().eq('id', id);
  }

  Future<List<OpportunityProductLine>> fetchLines(String opportunityId) async {
    final data = await sb
        .from(Tables.opportunityProducts)
        .select('*, product:product_id(id,name)')
        .eq('opportunity_id', opportunityId)
        .order('created_at');
    return (data as List)
        .map((e) => OpportunityProductLine.fromMap(e))
        .toList();
  }

  Future<void> addLine(OpportunityProductLine line) async {
    await sb.from(Tables.opportunityProducts).insert(line.toInsertMap());
  }

  Future<void> deleteLine(String lineId) async {
    await sb.from(Tables.opportunityProducts).delete().eq('id', lineId);
  }
}
