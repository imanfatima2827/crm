import '../core/supabase_client.dart';
import '../core/constants.dart';

class DashboardKpis {
  final int newLeads;
  final int qualifiedLeads;
  final int activeDeals;
  final int wonDeals;
  final double salesValue;
  final double? conversionRatePercent;

  DashboardKpis({
    required this.newLeads,
    required this.qualifiedLeads,
    required this.activeDeals,
    required this.wonDeals,
    required this.salesValue,
    required this.conversionRatePercent,
  });

  factory DashboardKpis.fromMap(Map<String, dynamic> map) => DashboardKpis(
    newLeads: (map['new_leads'] as num?)?.toInt() ?? 0,
    qualifiedLeads: (map['qualified_leads'] as num?)?.toInt() ?? 0,
    activeDeals: (map['active_deals'] as num?)?.toInt() ?? 0,
    wonDeals: (map['won_deals'] as num?)?.toInt() ?? 0,
    salesValue: (map['sales_value'] as num?)?.toDouble() ?? 0,
    conversionRatePercent: (map['conversion_rate_percent'] as num?)?.toDouble(),
  );

  factory DashboardKpis.empty() => DashboardKpis(
    newLeads: 0,
    qualifiedLeads: 0,
    activeDeals: 0,
    wonDeals: 0,
    salesValue: 0,
    conversionRatePercent: 0,
  );
}

class LeadsByStatusRow {
  final String status;
  final int count;
  LeadsByStatusRow(this.status, this.count);
}

class DealsByStageRow {
  final int stageId;
  final String stageName;
  final String stageSlug;
  final int dealCount;
  final double pipelineValue;
  DealsByStageRow({
    required this.stageId,
    required this.stageName,
    required this.stageSlug,
    required this.dealCount,
    required this.pipelineValue,
  });
}

class MonthlySalesRow {
  final DateTime monthStart;
  final int wonDeals;
  final double revenue;
  MonthlySalesRow(this.monthStart, this.wonDeals, this.revenue);
}

class DashboardRepository {
  Future<DashboardKpis> fetchKpis() async {
    final data = await sb.from(Tables.vDashboardKpis).select().maybeSingle();
    if (data == null) return DashboardKpis.empty();
    return DashboardKpis.fromMap(data);
  }

  Future<List<LeadsByStatusRow>> fetchLeadsByStatus() async {
    final data = await sb.from(Tables.vLeadsByStatus).select();
    return (data as List)
        .map(
          (e) => LeadsByStatusRow(
            e['status'] as String,
            (e['lead_count'] as num).toInt(),
          ),
        )
        .toList();
  }

  Future<List<DealsByStageRow>> fetchDealsByStage() async {
    final data = await sb.from(Tables.vDealsByStage).select();
    return (data as List)
        .map(
          (e) => DealsByStageRow(
            stageId: e['stage_id'] as int,
            stageName: e['stage_name'] as String,
            stageSlug: e['stage_slug'] as String,
            dealCount: (e['deal_count'] as num).toInt(),
            pipelineValue: (e['pipeline_value'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<MonthlySalesRow>> fetchMonthlySales() async {
    final data = await sb.from(Tables.vMonthlySales).select();
    return (data as List)
        .map(
          (e) => MonthlySalesRow(
            DateTime.parse(e['month_start'] as String),
            (e['won_deals'] as num).toInt(),
            (e['revenue'] as num).toDouble(),
          ),
        )
        .toList();
  }
}
