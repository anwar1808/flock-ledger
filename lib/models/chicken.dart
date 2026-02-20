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
  final bool isActive;
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
    this.isActive = true,
    required this.createdAt,
  });

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
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

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
    bool? isActive,
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
      isActive: isActive ?? this.isActive,
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
