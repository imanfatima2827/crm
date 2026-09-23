class Customer {
  final String id;
  final String? sourceLeadId;
  final String customerName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateRegion;
  final String? postalCode;
  final String? country;
  final String? assignedTo;
  final String? assignedToName;
  final String customerType;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Customer({
    required this.id,
    this.sourceLeadId,
    required this.customerName,
    this.companyName,
    this.email,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateRegion,
    this.postalCode,
    this.country,
    this.assignedTo,
    this.assignedToName,
    required this.customerType,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    final assignee = map['assignee'] as Map<String, dynamic>?;
    return Customer(
      id: map['id'] as String,
      sourceLeadId: map['source_lead_id'] as String?,
      customerName: map['customer_name'] as String,
      companyName: map['company_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      addressLine1: map['address_line_1'] as String?,
      addressLine2: map['address_line_2'] as String?,
      city: map['city'] as String?,
      stateRegion: map['state_region'] as String?,
      postalCode: map['postal_code'] as String?,
      country: map['country'] as String?,
      assignedTo: map['assigned_to'] as String?,
      assignedToName: assignee?['full_name'] as String?,
      customerType: map['customer_type'] as String? ?? 'individual',
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'customer_name': customerName,
    'company_name': companyName,
    'email': email,
    'phone': phone,
    'address_line_1': addressLine1,
    'address_line_2': addressLine2,
    'city': city,
    'state_region': stateRegion,
    'postal_code': postalCode,
    'country': country,
    'assigned_to': assignedTo,
    'customer_type': customerType,
    'status': status,
    'notes': notes,
  };
}
