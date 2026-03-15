import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chicken.dart';
import '../models/flock_group.dart';
import '../database/database_helper.dart';

class ChickenProvider extends ChangeNotifier {
  List<Chicken> _chickens = [];
  List<FlockGroup> _flockGroups = [];
  bool _loading = false;

  List<Chicken> get chickens => _chickens;
  List<FlockGroup> get flockGroups => _flockGroups;
  List<Chicken> get activeChickens =>
      _chickens.where((c) => c.isActive).toList();
  bool get loading => _loading;

  Future<void> loadChickens() async {
    _loading = true;
    notifyListeners();
    _chickens = await DatabaseHelper.instance.getAllChickens();
    _flockGroups = await DatabaseHelper.instance.getAllFlockGroups();
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

  /// Returns chickens belonging to the given group.
  List<Chicken> chickensInGroup(String groupId) =>
      _chickens.where((c) => c.flockGroupId == groupId).toList();

  /// Returns chickens not assigned to any group.
  List<Chicken> get ungroupedChickens =>
      _chickens.where((c) => c.flockGroupId == null).toList();
}
