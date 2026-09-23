class LeadSource {
  final int id;
  final String name;
  final bool isActive;

  LeadSource({required this.id, required this.name, required this.isActive});

  factory LeadSource.fromMap(Map<String, dynamic> map) => LeadSource(
    id: map['id'] as int,
    name: map['name'] as String,
    isActive: (map['is_active'] as bool?) ?? true,
  );
}

class OpportunityStage {
  final int id;
  final String name;
  final String slug;
  final int sortOrder;
  final int defaultProbability;
  final bool isClosed;
  final bool isWon;
  final bool isLost;
  final bool isActive;

  OpportunityStage({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.defaultProbability,
    required this.isClosed,
    required this.isWon,
    required this.isLost,
    required this.isActive,
  });

  factory OpportunityStage.fromMap(Map<String, dynamic> map) =>
      OpportunityStage(
        id: map['id'] as int,
        name: map['name'] as String,
        slug: map['slug'] as String,
        sortOrder: map['sort_order'] as int,
        defaultProbability: map['default_probability'] as int,
        isClosed: (map['is_closed'] as bool?) ?? false,
        isWon: (map['is_won'] as bool?) ?? false,
        isLost: (map['is_lost'] as bool?) ?? false,
        isActive: (map['is_active'] as bool?) ?? true,
      );
}

class Product {
  final String id;
  final String name;
  final String? sku;
  final String productType; // product | service
  final String? category;
  final double standardPrice;
  final String? description;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.productType,
    this.category,
    required this.standardPrice,
    this.description,
    required this.isActive,
  });

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String,
    name: map['name'] as String,
    sku: map['sku'] as String?,
    productType: map['product_type'] as String? ?? 'service',
    category: map['category'] as String?,
    standardPrice: (map['standard_price'] as num?)?.toDouble() ?? 0,
    description: map['description'] as String?,
    isActive: (map['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toInsertMap() => {
    'name': name,
    if (sku != null && sku!.isNotEmpty) 'sku': sku,
    'product_type': productType,
    'category': category,
    'standard_price': standardPrice,
    'description': description,
    'is_active': isActive,
  };
}
