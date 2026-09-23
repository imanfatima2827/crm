class Lead {
  final String id;
  final String leadName;
  final String? companyName;
  final String? email;
  final String? phone;
  final int? sourceId;
  final String? sourceName; // joined
  final String? interestedProductId;
  final String? interestedProductName; // joined
  final String? interestDetails;
  final String? assignedTo;
  final String? assignedToName; // joined
  final String status;
  final String? notes;
  final String? lostReason;
  final DateTime? convertedAt;
  final DateTime createdAt;

  Lead({
    required this.id,
    required this.leadName,
    this.companyName,
    this.email,
    this.phone,
    this.sourceId,
    this.sourceName,
    this.interestedProductId,
    this.interestedProductName,
    this.interestDetails,
    this.assignedTo,
    this.assignedToName,
    required this.status,
    this.notes,
    this.lostReason,
    this.convertedAt,
    required this.createdAt,
  });

  factory Lead.fromMap(Map<String, dynamic> map) {
    final source = map['lead_sources'] as Map<String, dynamic>?;
    final product = map['interested_product'] as Map<String, dynamic>?;
    final assignee = map['assignee'] as Map<String, dynamic>?;
    return Lead(
      id: map['id'] as String,
      leadName: map['lead_name'] as String,
      companyName: map['company_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      sourceId: map['source_id'] as int?,
      sourceName: source?['name'] as String?,
      interestedProductId: map['interested_product_id'] as String?,
      interestedProductName: product?['name'] as String?,
      interestDetails: map['interest_details'] as String?,
      assignedTo: map['assigned_to'] as String?,
      assignedToName: assignee?['full_name'] as String?,
      status: map['status'] as String? ?? 'new',
      notes: map['notes'] as String?,
      lostReason: map['lost_reason'] as String?,
      convertedAt: map['converted_at'] != null
          ? DateTime.parse(map['converted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'lead_name': leadName,
    'company_name': companyName,
    'email': email,
    'phone': phone,
    'source_id': sourceId,
    'interested_product_id': interestedProductId,
    'interest_details': interestDetails,
    'assigned_to': assignedTo,
    'status': status,
    'notes': notes,
    'lost_reason': lostReason,
  };
}
