class EggRecord {
  final String id;
  final String? chickenId;
  final String? breedNote; // free-text note for unassigned eggs
  final double weightGrams;
  final String eggColorCategory;
  final DateTime date;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;

  const EggRecord({
    required this.id,
    this.chickenId,
    this.breedNote,
    required this.weightGrams,
    required this.eggColorCategory,
    required this.date,
    this.photoPath,
    this.notes,
    required this.createdAt,
  });

  /// USDA egg size grade based on weight.
  String get sizeGrade {
    if (weightGrams < 42) return 'Peewee';
    if (weightGrams < 49) return 'Small';
    if (weightGrams < 56) return 'Medium';
    if (weightGrams < 63) return 'Large';
    if (weightGrams < 70) return 'XL';
    return 'Jumbo';
  }

  bool get isAssigned => chickenId != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chicken_id': chickenId,
      'breed_note': breedNote,
      'weight_grams': weightGrams,
      'egg_color_category': eggColorCategory,
      'date': date.toIso8601String(),
      'photo_path': photoPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EggRecord.fromMap(Map<String, dynamic> map) {
    return EggRecord(
      id: map['id'] as String,
      chickenId: map['chicken_id'] as String?,
      breedNote: map['breed_note'] as String?,
      weightGrams: (map['weight_grams'] as num).toDouble(),
      eggColorCategory: map['egg_color_category'] as String,
      date: DateTime.parse(map['date'] as String),
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  EggRecord copyWith({
    String? id,
    String? chickenId,
    String? breedNote,
    double? weightGrams,
    String? eggColorCategory,
    DateTime? date,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
  }) {
    return EggRecord(
      id: id ?? this.id,
      chickenId: chickenId ?? this.chickenId,
      breedNote: breedNote ?? this.breedNote,
      weightGrams: weightGrams ?? this.weightGrams,
      eggColorCategory: eggColorCategory ?? this.eggColorCategory,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
