import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/egg_grade_standard.dart';

enum WeightUnit { grams, oz }

class SettingsProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _standardKey = 'egg_grading_standard';
  static const _unitKey = 'weight_unit';

  EggGradeStandard _gradingStandard = EggGradeStandard.ukEu;
  WeightUnit _weightUnit = WeightUnit.grams;

  EggGradeStandard get gradingStandard => _gradingStandard;
  WeightUnit get weightUnit => _weightUnit;

  Future<void> load() async {
    final standardStr = await _storage.read(key: _standardKey);
    final unitStr = await _storage.read(key: _unitKey);
    _gradingStandard = EggGradeHelper.fromKey(standardStr);
    _weightUnit = unitStr == 'oz' ? WeightUnit.oz : WeightUnit.grams;
    notifyListeners();
  }

  Future<void> setGradingStandard(EggGradeStandard standard) async {
    _gradingStandard = standard;
    await _storage.write(
        key: _standardKey, value: EggGradeHelper.standardKey(standard));
    notifyListeners();
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    _weightUnit = unit;
    await _storage.write(key: _unitKey, value: unit == WeightUnit.oz ? 'oz' : 'g');
    notifyListeners();
  }

  /// Format [grams] for display in the active unit.
  String formatWeight(double grams) {
    if (_weightUnit == WeightUnit.oz) {
      return '${(grams / 28.3495).toStringAsFixed(1)} oz';
    }
    return '${grams.toStringAsFixed(1)} g';
  }

  /// Convert a value entered in the active unit to grams.
  double toGrams(double value) {
    return _weightUnit == WeightUnit.oz ? value * 28.3495 : value;
  }

  /// Convert grams to the active display unit value (number only).
  double fromGrams(double grams) {
    return _weightUnit == WeightUnit.oz ? grams / 28.3495 : grams;
  }

  String get unitLabel => _weightUnit == WeightUnit.oz ? 'oz' : 'g';
}
