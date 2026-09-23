import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/csv_export.dart';
import '../../models/customer.dart';
import '../../services/customer_repository.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

enum _SortBy { newest, oldest, nameAZ }

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});
  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _repo = CustomerRepository();
  final _searchCtrl = TextEditingController();
  String? _status;
  _SortBy _sort = _SortBy.newest;
  late Future<List<Customer>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchCustomers();
  }

  void _reload() {
    setState(() {
      _future = _repo
          .fetchCustomers(status: _status, search: _searchCtrl.text)
          .then(_applySort);
    });
  }

  List<Customer> _applySort(List<Customer> customers) {
    final sorted = [...customers];
    switch (_sort) {
      case _SortBy.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortBy.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortBy.nameAZ:
        sorted.sort(
          (a, b) => a.customerName.toLowerCase().compareTo(
            b.customerName.toLowerCase(),
          ),
        );
        break;
    }
    return sorted;
  }

  Future<void> _exportCsv(List<Customer> customers) async {
    try {
      await exportAndShareCsv(
        filename: 'customers.csv',
        headers: const [
          'Customer Name',
          'Company',
          'Email',
          'Phone',
          'City',
          'Country',
          'Type',
          'Status',
          'Assigned To',
          'Created At',
        ],
        rows: [
          for (final c in customers)
            [
              c.customerName,
              c.companyName ?? '',
              c.email ?? '',
              c.phone ?? '',
              c.city ?? '',
              c.country ?? '',
              c.customerType,
              c.status,
              c.assignedToName ?? 'Unassigned',
              DateFormat('yyyy-MM-dd').format(c.createdAt),
            ],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Export failed');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search name, company, email, phone',
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _reload();
                              },
                            ),
                    ),
                    onSubmitted: (_) => _reload(),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_SortBy>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort),
                  initialValue: _sort,
                  onSelected: (v) {
                    setState(() => _sort = v);
                    _reload();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _SortBy.newest,
                      child: Text('Newest first'),
                    ),
                    PopupMenuItem(
                      value: _SortBy.oldest,
                      child: Text('Oldest first'),
                    ),
                    PopupMenuItem(
                      value: _SortBy.nameAZ,
                      child: Text('Name (A\u2013Z)'),
                    ),
                  ],
                ),
                FutureBuilder<List<Customer>>(
                  future: _future,
                  builder: (context, snap) {
                    final customers = snap.data ?? [];
                    return IconButton(
                      tooltip: 'Export CSV',
                      icon: const Icon(Icons.ios_share),
                      onPressed: customers.isEmpty
                          ? null
                          : () => _exportCsv(customers),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipsRow(
              options: const ['active', 'inactive'],
              selected: _status,
              onSelected: (v) {
                setState(() => _status = v);
                _reload();
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorRetryView(
                    message: 'Failed to load customers.\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                final customers = snap.data!;
                if (customers.isEmpty) {
                  return EmptyState(
                    message: 'No customers found',
                    icon: Icons.groups_outlined,
                    action: OutlinedButton.icon(
                      onPressed: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const CustomerFormScreen(),
                          ),
                        );
                        if (created == true) _reload();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add your first customer'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = customers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor(
                            c.status,
                          ).withValues(alpha: 0.12),
                          child: Text(
                            c.customerName.isNotEmpty
                                ? c.customerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: statusColor(c.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          c.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (c.companyName != null &&
                                c.companyName!.isNotEmpty)
                              c.companyName,
                            c.assignedToName ?? 'Unassigned',
                          ].whereType<String>().join(' \u00b7 '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: StatusBadge(status: c.status),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customerId: c.id),
                            ),
                          );
                          _reload();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
