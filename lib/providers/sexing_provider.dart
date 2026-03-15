import 'package:flutter/foundation.dart';
import '../models/sexing_assessment.dart';
import '../database/database_helper.dart';

class SexingProvider extends ChangeNotifier {
  final Map<String, List<SexingAssessment>> _byChicken = {};

  List<SexingAssessment> forChicken(String chickenId) =>
      _byChicken[chickenId] ?? [];

  Future<void> loadForChicken(String chickenId) async {
    final records =
        await DatabaseHelper.instance.getAssessmentsForChicken(chickenId);
    _byChicken[chickenId] = records;
    notifyListeners();
  }

  Future<void> addAssessment(SexingAssessment assessment) async {
    await DatabaseHelper.instance.insertSexingAssessment(assessment);
    _byChicken.putIfAbsent(assessment.chickenId, () => [])
        .insert(0, assessment);
    notifyListeners();
  }

  Future<void> deleteAssessment(String id, String chickenId) async {
    await DatabaseHelper.instance.deleteSexingAssessment(id);
    _byChicken[chickenId]?.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void removeForChicken(String chickenId) {
    _byChicken.remove(chickenId);
    notifyListeners();
  }
}
