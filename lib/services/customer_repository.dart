import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/customer.dart';

const _customerSelect = '''
  *,
  assignee:assigned_to(id,full_name)
''';

class CustomerRepository {
  Future<List<Customer>> fetchCustomers({
    String? status,
    String? assignedTo,
    String? search,
  }) async {
    var query = sb.from(Tables.customers).select(_customerSelect);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('assigned_to', assignedTo);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or(
        'customer_name.ilike.%$s%,company_name.ilike.%$s%,email.ilike.%$s%,phone.ilike.%$s%',
      );
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer> fetchCustomer(String id) async {
    final data = await sb
        .from(Tables.customers)
        .select(_customerSelect)
        .eq('id', id)
        .single();
    return Customer.fromMap(data);
  }

  Future<Customer> createCustomer(Customer customer) async {
    final data = await sb
        .from(Tables.customers)
        .insert(customer.toInsertMap())
        .select(_customerSelect)
        .single();
    return Customer.fromMap(data);
  }

  Future<Customer> updateCustomer(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final data = await sb
        .from(Tables.customers)
        .update(changes)
        .eq('id', id)
        .select(_customerSelect)
        .single();
    return Customer.fromMap(data);
  }

  Future<void> deleteCustomer(String id) async {
    await sb.from(Tables.customers).delete().eq('id', id);
  }
}
