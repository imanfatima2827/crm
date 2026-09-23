import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../models/lookups.dart';
import '../../services/product_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = ProductRepository();
  final _searchCtrl = TextEditingController();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAll();
  }

  void _reload() => setState(() {
    _future = _repo.fetchAll(search: _searchCtrl.text);
  });

  Future<void> _openForm({Product? existing}) async {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (!isAdmin) {
      showSnack(
        context,
        'Only Admins can manage the product catalog.',
        error: true,
      );
      return;
    }
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.standardPrice.toString() : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    String type = existing?.productType ?? 'service';
    bool active = existing?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          return AlertDialog(
            title: Text(
              existing == null ? 'New Product/Service' : 'Edit Product/Service',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: FieldValidators.requiredText,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: skuCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        for (final t in ProductType.values)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) => setD(() => type = v!),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoryCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Standard price *',
                      ),
                      validator: FieldValidators.nonNegativeNumber,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) => setD(() => active = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;
    try {
      final product = Product(
        id: existing?.id ?? '',
        name: nameCtrl.text.trim(),
        sku: skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
        productType: type,
        category: categoryCtrl.text.trim(),
        standardPrice: double.tryParse(priceCtrl.text.trim()) ?? 0,
        description: descCtrl.text.trim(),
        isActive: active,
      );
      if (existing == null) {
        await _repo.create(product);
      } else {
        await _repo.update(existing.id, product.toInsertMap());
      }
      if (!mounted) return;
      context.read<LookupProvider>().refreshProducts();
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Save failed');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('New Product'),
            )
          : null,
      body: Column(
        children: [
          if (!isAdmin)
            Container(
              width: double.infinity,
              color: AppColors.surfaceAlt,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Read-only \u2014 only Admins can add or edit products.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
                isDense: true,
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorRetryView(
                    message: 'Failed to load products.\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                final products = snap.data!;
                if (products.isEmpty) {
                  return const EmptyState(message: 'No products yet');
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          p.productType,
                          if (p.category != null && p.category!.isNotEmpty)
                            p.category,
                          if (p.sku != null && p.sku!.isNotEmpty)
                            'SKU: ${p.sku}',
                        ].whereType<String>().join(' \u00b7 '),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currency.format(p.standardPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (!p.isActive)
                            const StatusBadge(status: 'inactive'),
                        ],
                      ),
                      onTap: () => _openForm(existing: p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
