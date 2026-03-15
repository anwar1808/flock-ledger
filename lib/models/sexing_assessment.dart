class SexingAssessment {
  final String id;
  final String chickenId;
  final DateTime assessedAt;
  final int? ageWeeks;
  final String claudeResult;       // female | male | uncertain
  final String claudeConfidence;   // high | medium | low
  final String claudeReasoning;
  final String? claudeCaveats;
  final String? userCall;          // probably_female | probably_male | null
  final String displayedGender;   // what was saved to the flock page

  const SexingAssessment({
    required this.id,
    required this.chickenId,
    required this.assessedAt,
    this.ageWeeks,
    required this.claudeResult,
    required this.claudeConfidence,
    required this.claudeReasoning,
    this.claudeCaveats,
    this.userCall,
    required this.displayedGender,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chicken_id': chickenId,
        'assessed_at': assessedAt.toIso8601String(),
        'age_weeks': ageWeeks,
        'claude_result': claudeResult,
        'claude_confidence': claudeConfidence,
        'claude_reasoning': claudeReasoning,
        'claude_caveats': claudeCaveats,
        'user_call': userCall,
        'displayed_gender': displayedGender,
      };

  factory SexingAssessment.fromMap(Map<String, dynamic> map) =>
      SexingAssessment(
        id: map['id'] as String,
        chickenId: map['chicken_id'] as String,
        assessedAt: DateTime.parse(map['assessed_at'] as String),
        ageWeeks: map['age_weeks'] as int?,
        claudeResult: map['claude_result'] as String,
        claudeConfidence: map['claude_confidence'] as String,
        claudeReasoning: map['claude_reasoning'] as String,
        claudeCaveats: map['claude_caveats'] as String?,
        userCall: map['user_call'] as String?,
        displayedGender: map['displayed_gender'] as String,
      );
}
