class Opportunity {
  final String id;
  final String title;
  final String customerId;
  final String? customerName; // joined
  final int stageId;
  final String? stageName; // joined
  final String? stageSlug;
  final double estimatedValue;
  final DateTime expectedCloseDate;
  final String? assignedTo;
  final String? assignedToName;
  final int probability;
  final String? notes;
  final String? lossReason;
  final DateTime? wonAt;
  final DateTime? lostAt;
  final DateTime createdAt;

  Opportunity({
    required this.id,
    required this.title,
    required this.customerId,
    this.customerName,
    required this.stageId,
    this.stageName,
    this.stageSlug,
    required this.estimatedValue,
    required this.expectedCloseDate,
    this.assignedTo,
    this.assignedToName,
    required this.probability,
    this.notes,
    this.lossReason,
    this.wonAt,
    this.lostAt,
    required this.createdAt,
  });

  factory Opportunity.fromMap(Map<String, dynamic> map) {
    final customer = map['customer'] as Map<String, dynamic>?;
    final stage = map['stage'] as Map<String, dynamic>?;
    final assignee = map['assignee'] as Map<String, dynamic>?;
    return Opportunity(
      id: map['id'] as String,
      title: map['title'] as String,
      customerId: map['customer_id'] as String,
      customerName: customer?['customer_name'] as String?,
      stageId: map['stage_id'] as int,
      stageName: stage?['name'] as String?,
      stageSlug: stage?['slug'] as String?,
      estimatedValue: (map['estimated_value'] as num).toDouble(),
      expectedCloseDate: DateTime.parse(map['expected_close_date'] as String),
      assignedTo: map['assigned_to'] as String?,
      assignedToName: assignee?['full_name'] as String?,
      probability: map['probability'] as int? ?? 10,
      notes: map['notes'] as String?,
      lossReason: map['loss_reason'] as String?,
      wonAt: map['won_at'] != null
          ? DateTime.parse(map['won_at'] as String)
          : null,
      lostAt: map['lost_at'] != null
          ? DateTime.parse(map['lost_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'title': title,
    'customer_id': customerId,
    'stage_id': stageId,
    'estimated_value': estimatedValue,
    'expected_close_date': expectedCloseDate.toIso8601String().split('T').first,
    'assigned_to': assignedTo,
    'probability': probability,
    'notes': notes,
    'loss_reason': lossReason,
  };
}

class OpportunityProductLine {
  final String id;
  final String opportunityId;
  final String productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double lineTotal;

  OpportunityProductLine({
    required this.id,
    required this.opportunityId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.lineTotal,
  });

  factory OpportunityProductLine.fromMap(Map<String, dynamic> map) {
    final product = map['product'] as Map<String, dynamic>?;
    return OpportunityProductLine(
      id: map['id'] as String,
      opportunityId: map['opportunity_id'] as String,
      productId: map['product_id'] as String,
      productName: product?['name'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'opportunity_id': opportunityId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount_percent': discountPercent,
  };
}
