import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../models/chick_batch.dart';
import '../database/database_helper.dart';

class JournalProvider extends ChangeNotifier {
  List<JournalEntry> _entries = [];
  List<ChickBatch> _batches = [];
  bool _loading = false;

  List<JournalEntry> get entries => _entries;
  List<ChickBatch> get batches => _batches;
  bool get loading => _loading;

  List<JournalEntry> entriesByTrack(String trackType) =>
      _entries.where((e) => e.trackType == trackType).toList();

  List<JournalEntry> entriesForBatch(String batchId) =>
      _entries.where((e) => e.chickBatchId == batchId).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _entries = await DatabaseHelper.instance.getJournalEntries();
    _batches = await DatabaseHelper.instance.getAllChickBatches();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadEntries() async {
    _entries = await DatabaseHelper.instance.getJournalEntries();
    notifyListeners();
  }

  Future<void> loadBatches() async {
    _batches = await DatabaseHelper.instance.getAllChickBatches();
    notifyListeners();
  }

  // ─────────────── JOURNAL ENTRIES ───────────────

  Future<JournalEntry> addEntry({
    required String trackType,
    required String title,
    required String content,
    required DateTime date,
    String tags = '',
    List<String> photoPaths = const [],
    String? chickBatchId,
    String? chickStage,
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: const Uuid().v4(),
      trackType: trackType,
      title: title,
      content: content,
      date: date,
      tags: tags,
      photoPaths: photoPaths,
      chickBatchId: chickBatchId,
      chickStage: chickStage,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseHelper.instance.insertJournalEntry(entry);
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    return entry;
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await DatabaseHelper.instance.updateJournalEntry(updated);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseHelper.instance.deleteJournalEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ─────────────── CHICK BATCHES ───────────────

  Future<ChickBatch> addBatch({
    required String name,
    String? breed,
    required DateTime startDate,
    required int eggCount,
    String? incubatorType,
    String? notes,
    int incubationDays = 21,
    int hatchWindowDays = 3,
  }) async {
    final batch = ChickBatch(
      id: const Uuid().v4(),
      name: name,
      breed: breed,
      startDate: startDate,
      eggCount: eggCount,
      incubatorType: incubatorType,
      notes: notes,
      status: 'incubating',
      incubationDays: incubationDays,
      hatchWindowDays: hatchWindowDays,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertChickBatch(batch);
    _batches.insert(0, batch);
    notifyListeners();
    return batch;
  }

  Future<void> updateBatch(ChickBatch batch) async {
    await DatabaseHelper.instance.updateChickBatch(batch);
    final index = _batches.indexWhere((b) => b.id == batch.id);
    if (index != -1) {
      _batches[index] = batch;
      notifyListeners();
    }
  }

  Future<void> deleteBatch(String id) async {
    await DatabaseHelper.instance.deleteChickBatch(id);
    _batches.removeWhere((b) => b.id == id);
    _entries.removeWhere((e) => e.chickBatchId == id);
    notifyListeners();
  }

  ChickBatch? getBatchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
