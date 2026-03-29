import 'dart:convert';

class LossEvent {
  final String id;
  final String title;
  /// Status applied to affected birds: 'deceased'|'missing'|'slaughtered'
  final String statusApplied;
  final DateTime date;
  final List<String> affectedChickenIds;
  final String? notes;
  final DateTime createdAt;

  const LossEvent({
    required this.id,
    required this.title,
    required this.statusApplied,
    required this.date,
    required this.affectedChickenIds,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'status_applied': statusApplied,
        'date': date.toIso8601String(),
        'affected_chicken_ids_json': jsonEncode(affectedChickenIds),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory LossEvent.fromMap(Map<String, dynamic> map) => LossEvent(
        id: map['id'] as String,
        title: map['title'] as String,
        statusApplied: map['status_applied'] as String,
        date: DateTime.parse(map['date'] as String),
        affectedChickenIds: List<String>.from(
            jsonDecode(map['affected_chicken_ids_json'] as String)),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

const kLossStatuses = ['slaughtered', 'deceased', 'missing'];

const kLossStatusLabels = {
  'slaughtered': 'Slaughtered',
  'deceased': 'Deceased',
  'missing': 'Missing',
};
