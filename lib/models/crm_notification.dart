class CrmNotification {
  final String id;
  final String recipientId;
  final String notificationType;
  final String title;
  final String message;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final DateTime createdAt;

  CrmNotification({
    required this.id,
    required this.recipientId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.entityType,
    this.entityId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory CrmNotification.fromMap(Map<String, dynamic> map) => CrmNotification(
    id: map['id'] as String,
    recipientId: map['recipient_id'] as String,
    notificationType: map['notification_type'] as String,
    title: map['title'] as String,
    message: map['message'] as String,
    entityType: map['entity_type'] as String?,
    entityId: map['entity_id'] as String?,
    readAt: map['read_at'] != null
        ? DateTime.parse(map['read_at'] as String)
        : null,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
