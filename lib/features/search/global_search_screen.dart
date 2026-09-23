import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../services/search_repository.dart';
import '../leads/lead_detail_screen.dart';
import '../customers/customer_detail_screen.dart';
import '../pipeline/opportunity_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _repo = SearchRepository();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<SearchResult>? _results;
  bool _loading = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loading = true);
      try {
        final r = await _repo.searchAll(value);
        if (mounted) setState(() => _results = r);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _open(SearchResult r) {
    switch (r.type) {
      case SearchResultType.lead:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: r.id)),
        );
        break;
      case SearchResultType.customer:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customerId: r.id),
          ),
        );
        break;
      case SearchResultType.opportunity:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OpportunityDetailScreen(opportunityId: r.id),
          ),
        );
        break;
    }
  }

  IconData _iconFor(SearchResultType t) {
    switch (t) {
      case SearchResultType.lead:
        return Icons.person_add_alt_outlined;
      case SearchResultType.customer:
        return Icons.groups_outlined;
      case SearchResultType.opportunity:
        return Icons.handshake_outlined;
    }
  }

  String _labelFor(SearchResultType t) {
    switch (t) {
      case SearchResultType.lead:
        return 'Lead';
      case SearchResultType.customer:
        return 'Customer';
      case SearchResultType.opportunity:
        return 'Deal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search leads, customers, deals\u2026',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _results == null
          ? const EmptyState(
              message: 'Search across leads, customers, and deals at once.',
              icon: Icons.search,
            )
          : _results!.isEmpty
          ? const EmptyState(
              message: 'No matches found',
              icon: Icons.search_off,
            )
          : ListView.separated(
              itemCount: _results!.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _results![i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      _iconFor(r.type),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(r.title),
                  subtitle: Text(r.subtitle),
                  trailing: Chip(
                    label: Text(
                      _labelFor(r.type),
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => _open(r),
                );
              },
            ),
    );
  }
}
