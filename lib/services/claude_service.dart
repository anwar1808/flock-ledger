import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ClaudeEggResult {
  final double? weightGrams; // null if Claude couldn't read the scale
  final String eggColorCategory;

  const ClaudeEggResult({
    required this.weightGrams,
    required this.eggColorCategory,
  });
}

class ClaudeService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-opus-4-6';
  static const _maxTokens = 256;

  final String apiKey;
  ClaudeService(this.apiKey);

  /// Sends a compressed egg photo to Claude Vision and returns weight + colour.
  Future<ClaudeEggResult> analyzeEggPhoto(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Detect media type from file extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType =
        ext == 'png' ? 'image/png' : 'image/jpeg';

    final requestBody = {
      'model': _model,
      'max_tokens': _maxTokens,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': '''This is a photo of an egg on a weighing scale.
1. Read the weight shown on the scale display.
2. Identify the egg colour from this list:
   white, cream, light_brown, medium_brown, dark_brown,
   speckled_brown, blue, blue_green, pink, olive, green, unknown

Return ONLY valid JSON (no other text):
{
  "weight_grams": 58.3,
  "egg_color_category": "medium_brown"
}
If you cannot read the scale clearly, set weight_grams to null.''',
            },
          ],
        },
      ],
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw ClaudeServiceException(
          'API returned ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (responseData['content'] as List).first;
    final text = (content as Map<String, dynamic>)['text'] as String;

    // Extract JSON from the response (Claude should return only JSON)
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) {
      throw ClaudeServiceException(
          'Could not parse JSON from Claude response: $text');
    }

    final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

    final weightGrams = parsed['weight_grams'] != null
        ? (parsed['weight_grams'] as num).toDouble()
        : null;

    final eggColor =
        (parsed['egg_color_category'] as String?) ?? 'unknown';

    return ClaudeEggResult(
      weightGrams: weightGrams,
      eggColorCategory: eggColor,
    );
  }

  /// Sends one or more chick photos to Claude and returns a sex assessment.
  Future<ChickSexResult> analyzeChickSex(
    List<File> images, {
    String? breed,
    int? ageWeeks,
  }) async {
    final imageContents = <Map<String, dynamic>>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = image.path.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';
      imageContents.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mediaType,
          'data': base64Image,
        },
      });
    }

    final breedNote = breed != null && breed.isNotEmpty
        ? 'Breed: $breed. '
        : '';
    final ageNote = ageWeeks != null
        ? 'Age: approximately $ageWeeks weeks old. '
        : '';

    imageContents.add({
      'type': 'text',
      'text': '''${breedNote}${ageNote}Please assess the sex of the chick(s) in these photos based on visual cues such as comb size and development, feather growth patterns, body shape, colouring, and wattle development.

Return ONLY valid JSON (no other text):
{
  "likely_sex": "female",
  "confidence": "medium",
  "reasoning": "The comb is small and flat, feathering is even and rapid — both typical of pullets at this age.",
  "caveats": "Silkies are notoriously difficult to sex before 4-5 months — treat this as a rough guide only."
}

Rules:
- likely_sex must be exactly "female", "male", or "uncertain"
- confidence must be exactly "high", "medium", or "low"
- reasoning should be 1-3 sentences explaining the visual cues you used
- caveats is optional — include breed-specific or age-specific warnings if relevant, otherwise omit it
- If multiple chicks are shown, give the most common assessment across them and note variation in reasoning''',
    });

    final requestBody = {
      'model': _model,
      'max_tokens': 768,
      'messages': [
        {
          'role': 'user',
          'content': imageContents,
        },
      ],
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw ClaudeServiceException(
          'API returned ${response.statusCode}: ${response.body}');
    }

    final responseData =
        jsonDecode(response.body) as Map<String, dynamic>;
    final content = (responseData['content'] as List).first;
    final text = (content as Map<String, dynamic>)['text'] as String;

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) {
      throw ClaudeServiceException(
          'Could not parse JSON from Claude response: $text');
    }

    final parsed =
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

    return ChickSexResult(
      likelySex: parsed['likely_sex'] as String? ?? 'uncertain',
      confidence: parsed['confidence'] as String? ?? 'low',
      reasoning: parsed['reasoning'] as String? ?? '',
      caveats: parsed['caveats'] as String?,
    );
  }
}

class ChickSexResult {
  /// 'female' | 'male' | 'uncertain'
  final String likelySex;
  /// 'high' | 'medium' | 'low'
  final String confidence;
  final String reasoning;
  final String? caveats;

  const ChickSexResult({
    required this.likelySex,
    required this.confidence,
    required this.reasoning,
    this.caveats,
  });
}


class ClaudeServiceException implements Exception {
  final String message;
  const ClaudeServiceException(this.message);

  @override
  String toString() => 'ClaudeServiceException: $message';
}
