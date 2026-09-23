import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/quick_actions.dart';
import '../../models/customer.dart';
import '../../models/opportunity.dart';
import '../../models/activity.dart';
import '../../services/customer_repository.dart';
import '../../services/opportunity_repository.dart';
import '../../services/activity_repository.dart';
import 'customer_form_screen.dart';
import '../pipeline/opportunity_detail_screen.dart';
import '../pipeline/opportunity_form_screen.dart';
import '../activities/activity_form_screen.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _repo = CustomerRepository();
  final _oppRepo = OpportunityRepository();
  final _activityRepo = ActivityRepository();
  late Future<Customer> _future;
  List<Opportunity> _opportunities = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repo.fetchCustomer(widget.customerId).then((c) async {
      final results = await Future.wait([
        _oppRepo.fetchOpportunities().then(
          (all) => all.where((o) => o.customerId == c.id).toList(),
        ),
        _activityRepo.fetchActivities(customerId: c.id),
      ]);
      _opportunities = results[0] as List<Opportunity>;
      _activities = results[1] as List<Activity>;
      return c;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: FutureBuilder<Customer>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Failed to load customer.\n${snap.error}',
              onRetry: _load,
            );
          }
          final c = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.customerName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: c.status),
                ],
              ),
              if (c.companyName != null && c.companyName!.isNotEmpty)
                Text(
                  c.companyName!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 10),
              ContactQuickActions(phone: c.phone, email: c.email),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Email', c.email),
                      _row('Phone', c.phone),
                      _row(
                        'Address',
                        [
                          c.addressLine1,
                          c.addressLine2,
                          c.city,
                          c.stateRegion,
                          c.postalCode,
                          c.country,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                      ),
                      _row('Type', c.customerType),
                      _row('Assigned to', c.assignedToName ?? 'Unassigned'),
                      _row(
                        'Customer since',
                        DateFormat.yMMMd().format(c.createdAt),
                      ),
                      if (c.notes != null && c.notes!.isNotEmpty)
                        _row('Notes', c.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CustomerFormScreen(existing: c),
                        ),
                      );
                      if (updated == true) _load();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  if ([
                    c.addressLine1,
                    c.city,
                    c.country,
                  ].any((e) => e != null && e.isNotEmpty))
                    OutlinedButton.icon(
                      onPressed: () => launchMaps(
                        context,
                        [
                          c.addressLine1,
                          c.addressLine2,
                          c.city,
                          c.stateRegion,
                          c.postalCode,
                          c.country,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open in Maps'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              OpportunityFormScreen(customerId: c.id),
                        ),
                      );
                      if (created == true) _load();
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('New Opportunity'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ActivityFormScreen(customerId: c.id),
                        ),
                      );
                      if (added == true) _load();
                    },
                    icon: const Icon(Icons.add_task_outlined),
                    label: const Text('Log Activity'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Opportunities',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_opportunities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No opportunities yet.'),
                )
              else
                for (final o in _opportunities)
                  Card(
                    child: ListTile(
                      title: Text(o.title),
                      subtitle: Text(_currency.format(o.estimatedValue)),
                      trailing: StatusBadge(
                        status: o.stageSlug ?? '',
                        label: o.stageName,
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OpportunityDetailScreen(opportunityId: o.id),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
              const SizedBox(height: 24),
              Text(
                'Activities',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No activities logged yet.'),
                )
              else
                for (final a in _activities)
                  Card(
                    child: ListTile(
                      title: Text(a.subject),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(a.scheduledAt),
                      ),
                      trailing: StatusBadge(status: a.status),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
