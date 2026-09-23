class Activity {
  final String id;
  final String? leadId;
  final String? leadName;
  final String? customerId;
  final String? customerName;
  final String? opportunityId;
  final String? opportunityTitle;
  final String activityType;
  final String subject;
  final String? description;
  final DateTime scheduledAt;
  final String priority;
  final String assignedTo;
  final String? assignedToName;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;

  Activity({
    required this.id,
    this.leadId,
    this.leadName,
    this.customerId,
    this.customerName,
    this.opportunityId,
    this.opportunityTitle,
    required this.activityType,
    required this.subject,
    this.description,
    required this.scheduledAt,
    required this.priority,
    required this.assignedTo,
    this.assignedToName,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    final lead = map['lead'] as Map<String, dynamic>?;
    final customer = map['customer'] as Map<String, dynamic>?;
    final opportunity = map['opportunity'] as Map<String, dynamic>?;
    final assignee = map['assignee'] as Map<String, dynamic>?;
    return Activity(
      id: map['id'] as String,
      leadId: map['lead_id'] as String?,
      leadName: lead?['lead_name'] as String? ?? map['lead_name'] as String?,
      customerId: map['customer_id'] as String?,
      customerName:
          customer?['customer_name'] as String? ??
          map['customer_name'] as String?,
      opportunityId: map['opportunity_id'] as String?,
      opportunityTitle:
          opportunity?['title'] as String? ??
          map['opportunity_title'] as String?,
      activityType: map['activity_type'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String?,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      priority: map['priority'] as String? ?? 'normal',
      assignedTo: map['assigned_to'] as String,
      assignedToName: assignee?['full_name'] as String?,
      status: map['status'] as String? ?? 'pending',
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'lead_id': leadId,
    'customer_id': customerId,
    'opportunity_id': opportunityId,
    'activity_type': activityType,
    'subject': subject,
    'description': description,
    'scheduled_at': scheduledAt.toIso8601String(),
    'priority': priority,
    'assigned_to': assignedTo,
    'status': status,
  };
}
