class ChickBatch {
  final String id;
  final String name;
  final String? breed;
  final DateTime startDate;
  final int eggCount;
  final int? eggsHatched;
  final String? incubatorType;
  final String? notes;
  final String status; // 'incubating', 'hatching', 'raising', 'growing', 'completed'
  final DateTime createdAt;

  const ChickBatch({
    required this.id,
    required this.name,
    this.breed,
    required this.startDate,
    required this.eggCount,
    this.eggsHatched,
    this.incubatorType,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  /// Expected hatch date is 21 days after start.
  DateTime get expectedHatchDate => startDate.add(const Duration(days: 21));

  /// Days since incubation started (capped at 21).
  int get daysIncubated {
    final days = DateTime.now().difference(startDate).inDays;
    return days.clamp(0, 21);
  }

  /// Days remaining until expected hatch (0 if past).
  int get daysRemaining => (21 - daysIncubated).clamp(0, 21);

  /// Incubation progress as 0.0–1.0.
  double get incubationProgress => daysIncubated / 21.0;

  /// Hatch rate percentage (null if eggs_hatched not set).
  double? get hatchRate =>
      eggsHatched != null ? eggsHatched! / eggCount * 100 : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'start_date': startDate.toIso8601String(),
      'egg_count': eggCount,
      'eggs_hatched': eggsHatched,
      'incubator_type': incubatorType,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChickBatch.fromMap(Map<String, dynamic> map) {
    return ChickBatch(
      id: map['id'] as String,
      name: map['name'] as String,
      breed: map['breed'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      eggCount: map['egg_count'] as int,
      eggsHatched: map['eggs_hatched'] as int?,
      incubatorType: map['incubator_type'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ChickBatch copyWith({
    String? id,
    String? name,
    String? breed,
    DateTime? startDate,
    int? eggCount,
    int? eggsHatched,
    String? incubatorType,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return ChickBatch(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      startDate: startDate ?? this.startDate,
      eggCount: eggCount ?? this.eggCount,
      eggsHatched: eggsHatched ?? this.eggsHatched,
      incubatorType: incubatorType ?? this.incubatorType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const kBatchStatuses = [
  'incubating',
  'hatching',
  'raising',
  'growing',
  'completed',
];

const kBatchStatusLabels = {
  'incubating': 'Incubating',
  'hatching': 'Hatching',
  'raising': 'Raising Chicks',
  'growing': 'Growing Up',
  'completed': 'Completed',
};
