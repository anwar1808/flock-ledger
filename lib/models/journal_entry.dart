import 'dart:convert';

class JournalEntry {
  final String id;
  final String trackType; // 'general', 'flock', 'chick'
  final String title;
  final String content;
  final DateTime date; // the entry date — fully retroactive
  final String tags; // comma-separated free text
  final List<String> photoPaths;
  final String? chickBatchId;
  final String? chickStage;
  final DateTime createdAt; // when it was actually typed
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.trackType,
    required this.title,
    required this.content,
    required this.date,
    this.tags = '',
    this.photoPaths = const [],
    this.chickBatchId,
    this.chickStage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the entry date is before the day it was written.
  bool get isRetroactive {
    final entryDay = DateTime(date.year, date.month, date.day);
    final createdDay =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    return entryDay.isBefore(createdDay);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track_type': trackType,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'tags': tags,
      'photo_paths_json':
          photoPaths.isEmpty ? null : jsonEncode(photoPaths),
      'chick_batch_id': chickBatchId,
      'chick_stage': chickStage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    List<String> photos = [];
    if (map['photo_paths_json'] != null) {
      photos =
          List<String>.from(jsonDecode(map['photo_paths_json'] as String));
    }
    return JournalEntry(
      id: map['id'] as String,
      trackType: map['track_type'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.parse(map['date'] as String),
      tags: map['tags'] as String? ?? '',
      photoPaths: photos,
      chickBatchId: map['chick_batch_id'] as String?,
      chickStage: map['chick_stage'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  JournalEntry copyWith({
    String? id,
    String? trackType,
    String? title,
    String? content,
    DateTime? date,
    String? tags,
    List<String>? photoPaths,
    String? chickBatchId,
    String? chickStage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      trackType: trackType ?? this.trackType,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      photoPaths: photoPaths ?? this.photoPaths,
      chickBatchId: chickBatchId ?? this.chickBatchId,
      chickStage: chickStage ?? this.chickStage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const kTrackTypes = ['general', 'flock', 'chick'];

const kTrackTypeLabels = {
  'general': 'General',
  'flock': 'Flock',
  'chick': 'Chick',
};

const kChickStages = [
  'incubating',
  'hatching',
  'brooding',
  'weaning',
  'graduated',
];

const kChickStageLabels = {
  'incubating': 'Incubating',
  'hatching': 'Hatching Day',
  'brooding': 'Raising Chicks',
  'weaning': 'Growing Up',
  'graduated': 'Living Outside',
};
