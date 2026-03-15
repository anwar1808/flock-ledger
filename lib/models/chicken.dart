import 'dart:convert';

class Chicken {
  final String id;
  final String name;
  final String? breed;
  final DateTime? hatchDate;
  final String? color;
  final String? notes;
  final String? photoPath;
  final String? eggColorCategory;
  final List<String> eggSamplePhotos;
  /// 'active'|'deceased'|'missing'|'slaughtered'
  final String status;
  final DateTime? statusDate;
  final String? statusNote;
  final String? flockGroupId;
  /// 'female' | 'male' | 'unknown'
  final String gender;
  /// 'hatched' | 'bought'
  final String acquiredVia;
  final DateTime? buyDate;
  final int? ageAtPurchaseWeeks;
  final DateTime createdAt;

  const Chicken({
    required this.id,
    required this.name,
    this.breed,
    this.hatchDate,
    this.color,
    this.notes,
    this.photoPath,
    this.eggColorCategory,
    this.eggSamplePhotos = const [],
    this.status = 'active',
    this.statusDate,
    this.statusNote,
    this.flockGroupId,
    this.gender = 'unknown',
    this.acquiredVia = 'hatched',
    this.buyDate,
    this.ageAtPurchaseWeeks,
    required this.createdAt,
  });

  /// Convenience getter — true only when status is 'active'.
  bool get isActive => status == 'active';

  // ─── Computed age ───────────────────────────────────────────────────────────

  /// Best-known hatch date. For bought chickens, back-calculated from
  /// buy date and age at purchase.
  DateTime? get estimatedHatchDate {
    if (acquiredVia == 'hatched') return hatchDate;
    if (buyDate != null && ageAtPurchaseWeeks != null) {
      return buyDate!.subtract(Duration(days: ageAtPurchaseWeeks! * 7));
    }
    return hatchDate;
  }

  /// Age in days from estimated hatch date to today.
  int? get currentAgeInDays {
    final h = estimatedHatchDate;
    if (h == null) return null;
    return DateTime.now().difference(h).inDays.abs();
  }

  /// True when age is estimated (bought chicken).
  bool get isApproximateAge => acquiredVia == 'bought';

  /// Human-readable age string, e.g. "9 weeks", "7 months", "2 years 3 months".
  String get ageDisplay {
    final days = currentAgeInDays;
    if (days == null) return 'Unknown age';
    final weeks = days ~/ 7;
    if (weeks < 16) return '$weeks week${weeks == 1 ? '' : 's'}';
    final months = (days / 30.44).floor();
    if (months < 24) return '$months month${months == 1 ? '' : 's'}';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years year${years == 1 ? '' : 's'}';
    return '$years year${years == 1 ? '' : 's'} $rem month${rem == 1 ? '' : 's'}';
  }

  /// Age-and-gender-aware term: Pullet / Hen / Cockerel / Rooster / Chicken.
  String get displayTerm {
    if (gender == 'unknown') return 'Chicken';
    final days = currentAgeInDays;
    final isAdult = days == null || days >= 365;
    if (gender == 'female') return isAdult ? 'Hen' : 'Pullet';
    return isAdult ? 'Rooster' : 'Cockerel';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'hatch_date': hatchDate?.toIso8601String(),
      'color': color,
      'notes': notes,
      'photo_path': photoPath,
      'egg_color_category': eggColorCategory,
      'egg_sample_photos_json':
          eggSamplePhotos.isEmpty ? null : jsonEncode(eggSamplePhotos),
      'is_active': isActive ? 1 : 0,
      'status': status,
      'status_date': statusDate?.toIso8601String(),
      'status_note': statusNote,
      'flock_group_id': flockGroupId,
      'gender': gender,
      'acquired_via': acquiredVia,
      'buy_date': buyDate?.toIso8601String(),
      'age_at_purchase_weeks': ageAtPurchaseWeeks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Chicken.fromMap(Map<String, dynamic> map) {
    List<String> samplePhotos = [];
    if (map['egg_sample_photos_json'] != null) {
      samplePhotos =
          List<String>.from(jsonDecode(map['egg_sample_photos_json'] as String));
    }
    return Chicken(
      id: map['id'] as String,
      name: map['name'] as String,
      breed: map['breed'] as String?,
      hatchDate: map['hatch_date'] != null
          ? DateTime.parse(map['hatch_date'] as String)
          : null,
      color: map['color'] as String?,
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      eggColorCategory: map['egg_color_category'] as String?,
      eggSamplePhotos: samplePhotos,
      status: map['status'] as String? ??
          ((map['is_active'] as int? ?? 1) == 1 ? 'active' : 'deceased'),
      statusDate: map['status_date'] != null
          ? DateTime.parse(map['status_date'] as String)
          : null,
      statusNote: map['status_note'] as String?,
      flockGroupId: map['flock_group_id'] as String?,
      gender: map['gender'] as String? ?? 'unknown',
      acquiredVia: map['acquired_via'] as String? ??
          (map['hatch_date'] != null ? 'hatched' : 'hatched'),
      buyDate: map['buy_date'] != null
          ? DateTime.parse(map['buy_date'] as String)
          : null,
      ageAtPurchaseWeeks: map['age_at_purchase_weeks'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Sentinel to allow explicitly clearing nullable fields to null.
  static const _clear = Object();

  Chicken copyWith({
    String? id,
    String? name,
    String? breed,
    DateTime? hatchDate,
    String? color,
    String? notes,
    String? photoPath,
    String? eggColorCategory,
    List<String>? eggSamplePhotos,
    String? status,
    Object? statusDate = _clear,
    Object? statusNote = _clear,
    Object? flockGroupId = _clear,
    String? gender,
    String? acquiredVia,
    Object? buyDate = _clear,
    Object? ageAtPurchaseWeeks = _clear,
    DateTime? createdAt,
  }) {
    return Chicken(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      hatchDate: hatchDate ?? this.hatchDate,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      eggColorCategory: eggColorCategory ?? this.eggColorCategory,
      eggSamplePhotos: eggSamplePhotos ?? this.eggSamplePhotos,
      status: status ?? this.status,
      statusDate: identical(statusDate, _clear)
          ? this.statusDate
          : statusDate as DateTime?,
      statusNote: identical(statusNote, _clear)
          ? this.statusNote
          : statusNote as String?,
      flockGroupId: identical(flockGroupId, _clear)
          ? this.flockGroupId
          : flockGroupId as String?,
      gender: gender ?? this.gender,
      acquiredVia: acquiredVia ?? this.acquiredVia,
      buyDate: identical(buyDate, _clear)
          ? this.buyDate
          : buyDate as DateTime?,
      ageAtPurchaseWeeks: identical(ageAtPurchaseWeeks, _clear)
          ? this.ageAtPurchaseWeeks
          : ageAtPurchaseWeeks as int?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// The 12 egg colour categories used throughout the app.
const kEggColorCategories = [
  'white',
  'cream',
  'light_brown',
  'medium_brown',
  'dark_brown',
  'speckled_brown',
  'blue',
  'blue_green',
  'pink',
  'olive',
  'green',
  'unknown',
];

/// Human-readable labels for each category.
const kEggColorLabels = {
  'white': 'White',
  'cream': 'Cream',
  'light_brown': 'Light Brown',
  'medium_brown': 'Medium Brown',
  'dark_brown': 'Dark Brown',
  'speckled_brown': 'Speckled Brown',
  'blue': 'Blue',
  'blue_green': 'Blue-Green / Olive',
  'pink': 'Pink-Tinted',
  'olive': 'Dark Olive',
  'green': 'Green',
  'unknown': 'Unknown',
};
