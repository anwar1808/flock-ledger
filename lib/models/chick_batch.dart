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
  /// Standard incubation period for this breed (e.g. 21 for chickens, 28 for ducks).
  final int incubationDays;
  /// Extra days to wait past [expectedHatchDate] before giving up.
  final int hatchWindowDays;
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
    this.incubationDays = 21,
    this.hatchWindowDays = 3,
    required this.createdAt,
  });

  /// Expected hatch date based on breed incubation period.
  DateTime get expectedHatchDate =>
      startDate.add(Duration(days: incubationDays));

  /// Last date to wait before giving up — expected hatch + hatch window.
  DateTime get lastHatchDate =>
      startDate.add(Duration(days: incubationDays + hatchWindowDays));

  /// Total tracked days (incubation + hatch window).
  int get totalTrackedDays => incubationDays + hatchWindowDays;

  /// Days since incubation started, capped at [totalTrackedDays].
  int get daysIncubated {
    final days = DateTime.now().difference(startDate).inDays;
    return days.clamp(0, totalTrackedDays);
  }

  /// Days remaining until expected hatch (0 if at or past expected date).
  int get daysRemaining => (incubationDays - daysIncubated).clamp(0, incubationDays);

  /// Progress within the core incubation period as 0.0–1.0 (capped at 1.0).
  double get incubationProgress =>
      (daysIncubated / incubationDays).clamp(0.0, 1.0);

  /// True if we are past the expected hatch day but still within the window.
  bool get isInHatchWindow =>
      daysIncubated > incubationDays &&
      daysIncubated <= incubationDays + hatchWindowDays;

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
      'incubation_days': incubationDays,
      'hatch_window_days': hatchWindowDays,
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
      incubationDays: (map['incubation_days'] as int?) ?? 21,
      hatchWindowDays: (map['hatch_window_days'] as int?) ?? 3,
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
    int? incubationDays,
    int? hatchWindowDays,
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
      incubationDays: incubationDays ?? this.incubationDays,
      hatchWindowDays: hatchWindowDays ?? this.hatchWindowDays,
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
