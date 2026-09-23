import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/common.dart';
import '../../core/theme.dart';
import '../../services/dashboard_repository.dart';
import '../../services/activity_repository.dart';
import '../../models/activity.dart';
import '../../state/auth_provider.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  final _activityRepo = ActivityRepository();
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      _repo.fetchKpis(),
      _repo.fetchLeadsByStatus(),
      _repo.fetchDealsByStage(),
      _repo.fetchMonthlySales(),
      _activityRepo.fetchUpcoming(limit: 6),
      _activityRepo.fetchOverdue(limit: 6),
    ]);
    return _DashboardData(
      kpis: results[0] as DashboardKpis,
      leadsByStatus: results[1] as List<LeadsByStatusRow>,
      dealsByStage: results[2] as List<DealsByStageRow>,
      monthlySales: results[3] as List<MonthlySalesRow>,
      upcoming: results[4] as List<Activity>,
      overdue: results[5] as List<Activity>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Could not load dashboard.\n${snap.error}',
              onRetry: _refresh,
            );
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _GreetingBanner(
                name: context.watch<AuthProvider>().profile?.fullName,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _KpiGrid(
                cards: [
                  KpiCard(
                    label: 'New Leads',
                    value: '${data.kpis.newLeads}',
                    icon: Icons.person_add_alt,
                  ),
                  KpiCard(
                    label: 'Qualified Leads',
                    value: '${data.kpis.qualifiedLeads}',
                    icon: Icons.verified_outlined,
                  ),
                  KpiCard(
                    label: 'Active Deals',
                    value: '${data.kpis.activeDeals}',
                    icon: Icons.handshake_outlined,
                  ),
                  KpiCard(
                    label: 'Won Deals',
                    value: '${data.kpis.wonDeals}',
                    icon: Icons.emoji_events_outlined,
                  ),
                  KpiCard(
                    label: 'Sales Value',
                    value: _currency.format(data.kpis.salesValue),
                    icon: Icons.payments_outlined,
                  ),
                  KpiCard(
                    label: 'Conversion Rate',
                    value:
                        '${(data.kpis.conversionRatePercent ?? 0).toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 800;
                  final chart1 = _ChartCard(
                    title: 'Leads by Status',
                    icon: Icons.donut_large_outlined,
                    child: _LeadsByStatusChart(rows: data.leadsByStatus),
                  );
                  final chart2 = _ChartCard(
                    title: 'Pipeline by Stage',
                    icon: Icons.view_kanban_outlined,
                    child: _DealsByStageChart(rows: data.dealsByStage),
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [chart1, const SizedBox(height: 14), chart2],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: chart1),
                      const SizedBox(width: 14),
                      Expanded(child: chart2),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _ChartCard(
                title: 'Monthly Sales (last 12 months)',
                icon: Icons.show_chart_outlined,
                child: _MonthlySalesChart(rows: data.monthlySales),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 800;
                  final upcoming = _ActivityListCard(
                    title: 'Upcoming Activities',
                    activities: data.upcoming,
                    emptyText: 'No upcoming activities',
                  );
                  final overdue = _ActivityListCard(
                    title: 'Overdue Activities',
                    activities: data.overdue,
                    emptyText: 'Nothing overdue \u2014 great job!',
                    isOverdue: true,
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [upcoming, const SizedBox(height: 14), overdue],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: upcoming),
                      const SizedBox(width: 14),
                      Expanded(child: overdue),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lays KPI cards out in full-width rows (no leftover gap on the right
/// like a plain Wrap would leave), computing how many cards fit per row
/// from the available width and stretching each card to fill its share.
class _KpiGrid extends StatelessWidget {
  final List<Widget> cards;
  static const _minCardWidth = 150.0;
  static const _spacing = 14.0;
  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        int columns = ((maxWidth + _spacing) / (_minCardWidth + _spacing))
            .floor();
        columns = columns.clamp(1, cards.length);

        final rows = <Widget>[];
        for (int i = 0; i < cards.length; i += columns) {
          final rowItems = cards.skip(i).take(columns).toList();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int j = 0; j < rowItems.length; j++) ...[
                  if (j > 0) const SizedBox(width: _spacing),
                  Expanded(child: rowItems[j]),
                ],
                // Keep a short trailing row the same card width as the
                // rows above it, instead of stretching it wider.
                for (int j = rowItems.length; j < columns; j++) ...[
                  const SizedBox(width: _spacing),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          );
          if (i + columns < cards.length) {
            rows.add(const SizedBox(height: _spacing));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}

class _DashboardData {
  final DashboardKpis kpis;
  final List<LeadsByStatusRow> leadsByStatus;
  final List<DealsByStageRow> dealsByStage;
  final List<MonthlySalesRow> monthlySales;
  final List<Activity> upcoming;
  final List<Activity> overdue;
  _DashboardData({
    required this.kpis,
    required this.leadsByStatus,
    required this.dealsByStage,
    required this.monthlySales,
    required this.upcoming,
    required this.overdue,
  });
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

class _LeadsByStatusChart extends StatelessWidget {
  final List<LeadsByStatusRow> rows;
  const _LeadsByStatusChart({required this.rows});
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const EmptyState(message: 'No lead data yet');
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: [
                  for (final r in rows)
                    PieChartSectionData(
                      value: r.count.toDouble(),
                      color: statusColor(r.status),
                      title: total == 0
                          ? ''
                          : '${(r.count / total * 100).round()}%',
                      radius: 54,
                      titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusForegroundColor(r.status),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ListView(
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor(r.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${r.status[0].toUpperCase()}${r.status.substring(1)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${r.count}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DealsByStageChart extends StatelessWidget {
  final List<DealsByStageRow> rows;
  const _DealsByStageChart({required this.rows});
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const EmptyState(message: 'No pipeline data yet');
    final maxCount = rows.fold<int>(
      1,
      (m, r) => r.dealCount > m ? r.dealCount : m,
    );
    return BarChart(
      BarChartData(
        maxY: (maxCount + 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    rows[i].stageName,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: rows[i].dealCount.toDouble(),
                  color: statusColor(rows[i].stageSlug),
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthlySalesChart extends StatelessWidget {
  final List<MonthlySalesRow> rows;
  const _MonthlySalesChart({required this.rows});
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const EmptyState(message: 'No sales history yet');
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM').format(rows[i].monthStart),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < rows.length; i++)
                FlSpot(i.toDouble(), rows[i].revenue),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListCard extends StatelessWidget {
  final String title;
  final List<Activity> activities;
  final String emptyText;
  final bool isOverdue;
  const _ActivityListCard({
    required this.title,
    required this.activities,
    required this.emptyText,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  emptyText,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              for (final a in activities)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _iconFor(a.activityType),
                    size: 20,
                    color: isOverdue ? AppColors.danger : AppColors.primary,
                  ),
                  title: Text(
                    a.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    a.leadName ?? a.customerName ?? a.opportunityTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('MMM d, h:mm a').format(a.scheduledAt),
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'call':
        return Icons.call_outlined;
      case 'meeting':
        return Icons.groups_2_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'follow_up':
        return Icons.replay_outlined;
      default:
        return Icons.notes_outlined;
    }
  }
}

/// Professional solid-color header greeting the signed-in user with the
/// current date, shown at the top of the dashboard.
class _GreetingBanner extends StatelessWidget {
  final String? name;
  const _GreetingBanner({this.name});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (name ?? '').trim().split(' ').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? _greeting : '$_greeting, $firstName',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
