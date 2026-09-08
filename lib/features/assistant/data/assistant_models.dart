class AssistantMessage {
  const AssistantMessage({required this.id, required this.role, required this.content, required this.createdAt});
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  factory AssistantMessage.fromMap(Map<String, dynamic> map) => AssistantMessage(
        id: map['id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class AssistantConversation {
  const AssistantConversation({required this.id, this.title, required this.updatedAt});
  final String id;
  final String? title;
  final DateTime updatedAt;

  factory AssistantConversation.fromMap(Map<String, dynamic> map) => AssistantConversation(
        id: map['id'] as String,
        title: map['title'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
