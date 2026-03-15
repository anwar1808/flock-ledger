class FlockGroup {
  final String id;
  final String name;
  final String colorHex;
  final String? notes;
  final DateTime createdAt;

  const FlockGroup({
    required this.id,
    required this.name,
    required this.colorHex,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_hex': colorHex,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory FlockGroup.fromMap(Map<String, dynamic> map) => FlockGroup(
        id: map['id'] as String,
        name: map['name'] as String,
        colorHex: map['color_hex'] as String,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  FlockGroup copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? notes,
    DateTime? createdAt,
  }) =>
      FlockGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Preset colour swatches for flock groups.
const kFlockGroupColors = [
  '#5D8A3C', // earthy green
  '#D4A017', // golden amber
  '#8B4513', // saddle brown
  '#4A90D9', // sky blue
  '#E67E22', // orange
  '#9B59B6', // purple
  '#E74C3C', // red
  '#1ABC9C', // teal
  '#E91E8C', // pink
  '#607D8B', // blue-grey
];
