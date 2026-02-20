import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chicken.dart';
import '../database/database_helper.dart';

class ChickenProvider extends ChangeNotifier {
  List<Chicken> _chickens = [];
  bool _loading = false;

  List<Chicken> get chickens => _chickens;
  List<Chicken> get activeChickens =>
      _chickens.where((c) => c.isActive).toList();
  bool get loading => _loading;

  Future<void> loadChickens() async {
    _loading = true;
    notifyListeners();
    _chickens = await DatabaseHelper.instance.getAllChickens();
    _loading = false;
    notifyListeners();
  }

  Future<Chicken> addChicken({
    required String name,
    String? breed,
    DateTime? hatchDate,
    String? color,
    String? notes,
    String? photoPath,
    String? eggColorCategory,
    List<String> eggSamplePhotos = const [],
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
}
