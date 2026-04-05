class AiMessage {
  final String id;
  final String threadId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'thread_id': threadId,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiMessage.fromMap(Map<String, dynamic> map) => AiMessage(
        id: map['id'] as String,
        threadId: map['thread_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
