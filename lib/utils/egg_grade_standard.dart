/// Egg size grading standards supported by FlockLedger.
enum EggGradeStandard { ukEu, usda }

class EggGradeHelper {
  /// Returns the size grade label for [weightGrams] under [standard].
  static String sizeGrade(double weightGrams, EggGradeStandard standard) {
    return switch (standard) {
      EggGradeStandard.ukEu => _ukEuGrade(weightGrams),
      EggGradeStandard.usda => _usdaGrade(weightGrams),
    };
  }

  static String _ukEuGrade(double g) {
    if (g < 53) return 'S';
    if (g < 63) return 'M';
    if (g < 73) return 'L';
    return 'XL';
  }

  static String _usdaGrade(double g) {
    if (g < 42) return 'Peewee';
    if (g < 49) return 'Small';
    if (g < 56) return 'Medium';
    if (g < 63) return 'Large';
    if (g < 70) return 'XL';
    return 'Jumbo';
  }

  static String standardName(EggGradeStandard standard) => switch (standard) {
        EggGradeStandard.ukEu => 'UK / EU',
        EggGradeStandard.usda => 'US (USDA)',
      };

  static String standardKey(EggGradeStandard standard) => switch (standard) {
        EggGradeStandard.ukEu => 'uk_eu',
        EggGradeStandard.usda => 'usda',
      };

  static EggGradeStandard fromKey(String? key) => switch (key) {
        'usda' => EggGradeStandard.usda,
        _ => EggGradeStandard.ukEu, // default
      };
}
