import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/egg_record.dart';
import '../database/database_helper.dart';

class EggProvider extends ChangeNotifier {
  List<EggRecord> _records = [];
  bool _loading = false;

  List<EggRecord> get records => _records;
  bool get loading => _loading;

  List<EggRecord> recordsForChicken(String chickenId) =>
      _records.where((r) => r.chickenId == chickenId).toList();

  Future<void> loadRecords() async {
    _loading = true;
    notifyListeners();
    _records = await DatabaseHelper.instance.getAllEggRecords();
    _loading = false;
    notifyListeners();
  }

  Future<EggRecord> addRecord({
    String? chickenId,
    String? breedNote,
    required double weightGrams,
    required String eggColorCategory,
    required DateTime date,
    String? photoPath,
    String? notes,
  }) async {
    final record = EggRecord(
      id: const Uuid().v4(),
      chickenId: chickenId,
      breedNote: breedNote,
      weightGrams: weightGrams,
      eggColorCategory: eggColorCategory,
      date: date,
      photoPath: photoPath,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertEggRecord(record);
    _records.insert(0, record);
    _records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    return record;
  }

  Future<void> updateRecord(EggRecord record) async {
    await DatabaseHelper.instance.updateEggRecord(record);
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    await DatabaseHelper.instance.deleteEggRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ─────────────── STATS ───────────────

  double get averageWeight {
    if (_records.isEmpty) return 0;
    return _records.map((r) => r.weightGrams).reduce((a, b) => a + b) /
        _records.length;
  }

  double averageWeightForChicken(String chickenId) {
    final recs = recordsForChicken(chickenId);
    if (recs.isEmpty) return 0;
    return recs.map((r) => r.weightGrams).reduce((a, b) => a + b) / recs.length;
  }

  /// Returns eggs per week for the last 12 weeks as a list of (weekStart, count) pairs.
  List<MapEntry<DateTime, int>> eggsPerWeek({String? chickenId}) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, int>>[];
    for (int w = 11; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = _records
          .where((r) =>
              (chickenId == null || r.chickenId == chickenId) &&
              r.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              r.date.isBefore(weekEnd))
          .length;
      result.add(MapEntry(weekStart, count));
    }
    return result;
  }

  /// Groups eggs by month (key: 'YYYY-MM') and optional chicken.
  Map<String, int> eggsPerMonth({String? chickenId}) {
    final map = <String, int>{};
    for (final r in _records) {
      if (chickenId != null && r.chickenId != chickenId) continue;
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Size grade distribution across all records.
  Map<String, int> sizeGradeDistribution() {
    final map = <String, int>{};
    for (final r in _records) {
      map[r.sizeGrade] = (map[r.sizeGrade] ?? 0) + 1;
    }
    return map;
  }

  /// Returns eggs this week count across all or for one chicken.
  int eggsThisWeek({String? chickenId}) {
    final monday = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return _records
        .where((r) =>
            (chickenId == null || r.chickenId == chickenId) &&
            !r.date.isBefore(weekStart))
        .length;
  }
}
