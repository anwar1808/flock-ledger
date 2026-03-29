import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chicken.dart';
import '../models/flock_group.dart';
import '../models/loss_event.dart';
import '../database/database_helper.dart';

class ChickenProvider extends ChangeNotifier {
  List<Chicken> _chickens = [];
  List<FlockGroup> _flockGroups = [];
  List<LossEvent> _lossEvents = [];
  bool _loading = false;

  List<Chicken> get chickens => _chickens;
  List<FlockGroup> get flockGroups => _flockGroups;
  List<LossEvent> get lossEvents => _lossEvents;
  List<Chicken> get activeChickens =>
      _chickens.where((c) => c.status == 'active').toList();
  List<Chicken> get archivedChickens =>
      _chickens.where((c) => c.status != 'active').toList();
  bool get loading => _loading;

  Future<void> loadChickens() async {
    _loading = true;
    notifyListeners();
    _chickens = await DatabaseHelper.instance.getAllChickens();
    _flockGroups = await DatabaseHelper.instance.getAllFlockGroups();
    _lossEvents = await DatabaseHelper.instance.getAllLossEvents();
    _loading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // CHICKENS
  // ─────────────────────────────────────────

  Future<Chicken> addChicken({
    required String name,
    String? breed,
    DateTime? hatchDate,
    String? color,
    String? notes,
    String? photoPath,
    String? eggColorCategory,
    List<String> eggSamplePhotos = const [],
    String? flockGroupId,
    String gender = 'unknown',
    String acquiredVia = 'hatched',
    DateTime? buyDate,
    int? ageAtPurchaseWeeks,
    String purpose = 'layer',
    double? liveWeightGrams,
    double? dressedWeightGrams,
  }) async {
    final chicken = Chicken(
      id: const Uuid().v4(),
      name: name,
      breed: breed,
      hatchDate: hatchDate,
      color: color,
      notes: notes,
      photoPath: photoPath,
      eggColorCategory: eggColorCategory,
      eggSamplePhotos: eggSamplePhotos,
      flockGroupId: flockGroupId,
      gender: gender,
      acquiredVia: acquiredVia,
      buyDate: buyDate,
      ageAtPurchaseWeeks: ageAtPurchaseWeeks,
      purpose: purpose,
      liveWeightGrams: liveWeightGrams,
      dressedWeightGrams: dressedWeightGrams,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertChicken(chicken);
    _chickens.add(chicken);
    _chickens.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return chicken;
  }

  Future<void> updateChicken(Chicken chicken) async {
    await DatabaseHelper.instance.updateChicken(chicken);
    final index = _chickens.indexWhere((c) => c.id == chicken.id);
    if (index != -1) {
      _chickens[index] = chicken;
      _chickens.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteChicken(String id) async {
    await DatabaseHelper.instance.deleteChicken(id);
    _chickens.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Returns chickens whose egg_color_category matches the given colour.
  List<Chicken> findByEggColor(String eggColorCategory) {
    return activeChickens
        .where((c) => c.eggColorCategory == eggColorCategory)
        .toList();
  }

  Chicken? getById(String id) {
    try {
      return _chickens.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // FLOCK GROUPS
  // ─────────────────────────────────────────

  Future<FlockGroup> addFlockGroup({
    required String name,
    required String colorHex,
    String? notes,
  }) async {
    final group = FlockGroup(
      id: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertFlockGroup(group);
    _flockGroups.add(group);
    _flockGroups.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return group;
  }

  Future<void> updateFlockGroup(FlockGroup group) async {
    await DatabaseHelper.instance.updateFlockGroup(group);
    final index = _flockGroups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _flockGroups[index] = group;
      _flockGroups.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteFlockGroup(String id) async {
    await DatabaseHelper.instance.deleteFlockGroup(id);
    _flockGroups.removeWhere((g) => g.id == id);
    // Update in-memory chickens that were in this group
    _chickens = _chickens.map((c) {
      if (c.flockGroupId == id) {
        return c.copyWith(flockGroupId: null);
      }
      return c;
    }).toList();
    notifyListeners();
  }

  /// Converts ungrouped chickens into a named group.
  /// Creates the group then assigns all currently-ungrouped chickens to it.
  Future<FlockGroup> nameUngroupedChickens({
    required String name,
    String colorHex = '#5D8A3C',
  }) async {
    final group = await addFlockGroup(name: name, colorHex: colorHex);
    for (final chicken in ungroupedChickens) {
      final updated = chicken.copyWith(flockGroupId: group.id);
      await DatabaseHelper.instance.updateChicken(updated);
      final index = _chickens.indexWhere((c) => c.id == chicken.id);
      if (index != -1) _chickens[index] = updated;
    }
    notifyListeners();
    return group;
  }

  FlockGroup? getFlockGroupById(String id) {
    try {
      return _flockGroups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // LOSS EVENTS
  // ─────────────────────────────────────────

  /// Creates a loss event and updates each affected chicken's status.
  Future<LossEvent> logLossEvent({
    required String title,
    required String statusApplied,
    required DateTime date,
    required List<String> affectedChickenIds,
    String? notes,
  }) async {
    final event = LossEvent(
      id: const Uuid().v4(),
      title: title,
      statusApplied: statusApplied,
      date: date,
      affectedChickenIds: affectedChickenIds,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertLossEvent(event);
    _lossEvents.insert(0, event);

    // Update each affected chicken
    for (final id in affectedChickenIds) {
      final index = _chickens.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = _chickens[index].copyWith(
          status: statusApplied,
          statusDate: date,
          statusNote: title,
        );
        await DatabaseHelper.instance.updateChicken(updated);
        _chickens[index] = updated;
      }
    }
    notifyListeners();
    return event;
  }

  Future<void> deleteLossEvent(String id) async {
    await DatabaseHelper.instance.deleteLossEvent(id);
    _lossEvents.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Permanently deletes a flock group and every bird in it (plus their egg records via DB).
  Future<List<String>> deleteFlockGroupWithBirds(String groupId) async {
    final birdIds = chickensInGroup(groupId).map((c) => c.id).toList();
    await DatabaseHelper.instance.deleteChickensInGroup(groupId);
    await DatabaseHelper.instance.deleteFlockGroup(groupId);
    _chickens.removeWhere((c) => c.flockGroupId == groupId);
    _flockGroups.removeWhere((g) => g.id == groupId);
    notifyListeners();
    return birdIds; // caller can use these to clean up EggProvider
  }

  /// Creates multiple chickens from a single hatch, named "{prefix} 1", "{prefix} 2", …
  Future<List<Chicken>> addHatchBatch({
    required String prefix,
    required int count,
    required DateTime hatchDate,
    String? breed,
    String? flockGroupId,
  }) async {
    final created = <Chicken>[];
    for (var i = 1; i <= count; i++) {
      final chicken = Chicken(
        id: const Uuid().v4(),
        name: '$prefix $i',
        breed: breed,
        hatchDate: hatchDate,
        flockGroupId: flockGroupId,
        gender: 'unknown',
        acquiredVia: 'hatched',
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertChicken(chicken);
      created.add(chicken);
    }
    _chickens.addAll(created);
    _chickens.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return created;
  }

  /// Returns chickens belonging to the given group.
  List<Chicken> chickensInGroup(String groupId) =>
      _chickens.where((c) => c.flockGroupId == groupId).toList();

  /// Returns chickens not assigned to any group.
  List<Chicken> get ungroupedChickens =>
      _chickens.where((c) => c.flockGroupId == null).toList();
}
