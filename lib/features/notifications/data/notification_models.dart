class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'general',
      severity: map['severity'] as String? ?? 'info',
      title: map['title'] as String? ?? 'Notification',
      message: map['message'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
