class AiThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AiThread.fromMap(Map<String, dynamic> map) => AiThread(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  AiThread copyWith({String? title, DateTime? updatedAt}) => AiThread(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
