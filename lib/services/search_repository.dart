import '../core/supabase_client.dart';
import '../core/constants.dart';

enum SearchResultType { lead, customer, opportunity }

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class SearchRepository {
  Future<List<SearchResult>> searchAll(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final results = await Future.wait([
      sb
          .from(Tables.leads)
          .select('id, lead_name, company_name, status')
          .or(
            'lead_name.ilike.%$q%,company_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%',
          )
          .limit(8),
      sb
          .from(Tables.customers)
          .select('id, customer_name, company_name, status')
          .or(
            'customer_name.ilike.%$q%,company_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%',
          )
          .limit(8),
      sb
          .from(Tables.opportunities)
          .select('id, title, estimated_value')
          .ilike('title', '%$q%')
          .limit(8),
    ]);

    final leads = (results[0] as List)
        .map(
          (e) => SearchResult(
            type: SearchResultType.lead,
            id: e['id'] as String,
            title: e['lead_name'] as String,
            subtitle:
                (e['company_name'] as String?) ??
                (e['status'] as String? ?? ''),
          ),
        )
        .toList();

    final customers = (results[1] as List)
        .map(
          (e) => SearchResult(
            type: SearchResultType.customer,
            id: e['id'] as String,
            title: e['customer_name'] as String,
            subtitle:
                (e['company_name'] as String?) ??
                (e['status'] as String? ?? ''),
          ),
        )
        .toList();

    final opportunities = (results[2] as List)
        .map(
          (e) => SearchResult(
            type: SearchResultType.opportunity,
            id: e['id'] as String,
            title: e['title'] as String,
            subtitle: 'Deal',
          ),
        )
        .toList();

    return [...leads, ...customers, ...opportunities];
  }
}
