import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/csv_export.dart';
import '../../services/report_repository.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ReportRepository();
  late TabController _tab;

  final _titles = const [
    'Salesperson Performance',
    'Lead Source Performance',
    'Lead Conversion',
    'Won / Lost Deals',
    'Customer Activity',
    'Deal Value Breakdown',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _titles.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.surfaceCard,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: AppColors.primary,
              tabs: [for (final t in _titles) Tab(text: t)],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ReportTable(
                  future: _repo.fetchSalespersonPerformance(),
                  exportFilename: 'salesperson_performance.csv',
                  columns: const [
                    'salesperson',
                    'role_name',
                    'leads',
                    'qualified_leads',
                    'converted_leads',
                    'total_deals',
                    'won_deals',
                    'lost_deals',
                    'revenue',
                  ],
                  headers: const [
                    'Salesperson',
                    'Role',
                    'Leads',
                    'Qualified',
                    'Converted',
                    'Deals',
                    'Won',
                    'Lost',
                    'Revenue',
                  ],
                  currencyColumns: const ['revenue'],
                ),
                _ReportTable(
                  future: _repo.fetchLeadSourcePerformance(),
                  exportFilename: 'lead_source_performance.csv',
                  columns: const [
                    'source_name',
                    'total_leads',
                    'qualified_leads',
                    'converted_leads',
                    'conversion_rate_percent',
                  ],
                  headers: const [
                    'Source',
                    'Total Leads',
                    'Qualified',
                    'Converted',
                    'Conversion %',
                  ],
                  percentColumns: const ['conversion_rate_percent'],
                ),
                _ReportTable(
                  future: _repo.fetchLeadConversionReport(),
                  exportFilename: 'lead_conversion_report.csv',
                  columns: const [
                    'month_start',
                    'total_leads',
                    'currently_qualified',
                    'converted_leads',
                    'lost_leads',
                    'conversion_rate_percent',
                  ],
                  headers: const [
                    'Month',
                    'Total Leads',
                    'Qualified',
                    'Converted',
                    'Lost',
                    'Conversion %',
                  ],
                  dateColumns: const ['month_start'],
                  percentColumns: const ['conversion_rate_percent'],
                ),
                _ReportTable(
                  future: _repo.fetchWonLostOpportunities(),
                  exportFilename: 'won_lost_opportunities.csv',
                  columns: const [
                    'title',
                    'customer_name',
                    'salesperson',
                    'stage_name',
                    'estimated_value',
                    'won_at',
                    'lost_at',
                  ],
                  headers: const [
                    'Deal',
                    'Customer',
                    'Salesperson',
                    'Outcome',
                    'Value',
                    'Won At',
                    'Lost At',
                  ],
                  currencyColumns: const ['estimated_value'],
                  dateColumns: const ['won_at', 'lost_at'],
                ),
                _ReportTable(
                  future: _repo.fetchCustomerActivityReport(),
                  exportFilename: 'customer_activity_report.csv',
                  columns: const [
                    'customer_name',
                    'salesperson',
                    'total_activities',
                    'pending_activities',
                    'open_deals',
                    'won_deals',
                    'lifetime_won_value',
                  ],
                  headers: const [
                    'Customer',
                    'Salesperson',
                    'Activities',
                    'Pending',
                    'Open Deals',
                    'Won Deals',
                    'Lifetime Value',
                  ],
                  currencyColumns: const ['lifetime_won_value'],
                ),
                _ReportTable(
                  future: _repo.fetchOpportunityValueBreakdown(),
                  exportFilename: 'deal_value_breakdown.csv',
                  columns: const [
                    'title',
                    'estimated_value',
                    'product_line_total',
                    'estimate_minus_line_total',
                  ],
                  headers: const [
                    'Deal',
                    'Estimated Value',
                    'Product Line Total',
                    'Difference',
                  ],
                  currencyColumns: const [
                    'estimated_value',
                    'product_line_total',
                    'estimate_minus_line_total',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final List<String> columns;
  final List<String> headers;
  final String exportFilename;
  final List<String> currencyColumns;
  final List<String> percentColumns;
  final List<String> dateColumns;

  const _ReportTable({
    required this.future,
    required this.columns,
    required this.headers,
    required this.exportFilename,
    this.currencyColumns = const [],
    this.percentColumns = const [],
    this.dateColumns = const [],
  });

  String _formatCell(String col, dynamic value) {
    if (value == null) return '\u2014';
    if (currencyColumns.contains(col)) {
      return _currency.format((value as num).toDouble());
    }
    if (percentColumns.contains(col)) {
      return '${(value as num).toStringAsFixed(1)}%';
    }
    if (dateColumns.contains(col)) {
      try {
        return DateFormat.yMMMd().format(DateTime.parse(value.toString()));
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  Future<void> _export(
    BuildContext context,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await exportAndShareCsv(
        filename: exportFilename,
        headers: headers,
        rows: [
          for (final row in rows) [for (final col in columns) row[col] ?? ''],
        ],
      );
    } catch (e) {
      if (context.mounted) showError(context, e, prefix: 'Export failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return EmptyState(
            message: 'Failed to load report.\n${snap.error}',
            icon: Icons.error_outline,
          );
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return const EmptyState(message: 'No data available yet');
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${rows.length} rows',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _export(context, rows),
                    icon: const Icon(Icons.ios_share, size: 16),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.surfaceAlt,
                    ),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                    ),
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    columns: [
                      for (final h in headers) DataColumn(label: Text(h)),
                    ],
                    rows: [
                      for (int i = 0; i < rows.length; i++)
                        DataRow(
                          color: WidgetStateProperty.all(
                            i.isEven
                                ? AppColors.surfaceCard
                                : AppColors.rowStripe,
                          ),
                          cells: [
                            for (final col in columns)
                              DataCell(Text(_formatCell(col, rows[i][col]))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
