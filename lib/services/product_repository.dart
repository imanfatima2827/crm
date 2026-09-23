import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/lookups.dart';

class ProductRepository {
  Future<List<Product>> fetchAll({String? search, bool? activeOnly}) async {
    var query = sb.from(Tables.products).select();
    if (activeOnly == true) query = query.eq('is_active', true);
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or('name.ilike.%$s%,sku.ilike.%$s%,category.ilike.%$s%');
    }
    final data = await query.order('name');
    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<Product> create(Product p) async {
    final data = await sb
        .from(Tables.products)
        .insert(p.toInsertMap())
        .select()
        .single();
    return Product.fromMap(data);
  }

  Future<Product> update(String id, Map<String, dynamic> changes) async {
    final data = await sb
        .from(Tables.products)
        .update(changes)
        .eq('id', id)
        .select()
        .single();
    return Product.fromMap(data);
  }

  Future<void> delete(String id) async {
    await sb.from(Tables.products).delete().eq('id', id);
  }
}
