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

    final ageNote = ageWeeks != null
        ? 'Age: approximately $ageWeeks weeks old. '
        : '';

    imageContents.add({
      'type': 'text',
      'text': '''${ageNote}Please assess the sex of the chick(s) in these photos.

IMPORTANT: Base your assessment primarily on what you can directly observe in the images. Visual evidence is sovereign — breed context should only help you interpret genuinely ambiguous cues, never override clear ones.

Visual cues to assess (in order of reliability at this age):
1. Comb — size, height, redness, texture, and number of points
2. Feathering — rate and pattern of feather development on wings and back; symmetry between wing tip and body feathering
3. Wattles — any visible development or redness
4. Body shape and posture — overall proportions, stance
5. Colouring — any visible sex-linked colour differences

${_breedContext(breed)}Return ONLY valid JSON (no other text):
{
  "likely_sex": "female",
  "confidence": "medium",
  "reasoning": "The comb is small and pale. Wing feathering is noticeably more advanced than the back feathering, which is a consistent indicator of female in this breed at this age.",
  "caveats": "Sexing accuracy improves significantly after 6 weeks — treat this as a guide until then."
}

Rules:
- likely_sex must be exactly "female", "male", or "uncertain"
- confidence must be exactly "high", "medium", or "low"
- reasoning should be 2-4 sentences describing the specific visual cues you observed; if breed context influenced your interpretation, say how
- caveats is optional — include age limitations, breed-specific uncertainty, or anything the user should verify; omit if nothing important to add
- If multiple chicks are shown, give the dominant assessment and note any variation between individuals''',
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

/// Builds a breed context block for the sexing prompt.
String _breedContext(String? breed) {
  if (breed == null || breed.isEmpty) return '';
  return '''Breed context:
The breed/line is "$breed". Apply whatever you know about this specific breed or line — including growth rate profile, whether this line is known to carry sex-link feathering traits, typical comb development timeline, and any known plumage sex-link patterns. Use this knowledge to help interpret ambiguous visual cues only. Do not let breed assumptions override what is clearly visible in the photos. If you are uncertain about the characteristics of this specific line, say so in your caveats rather than guessing.

''';
}

class ClaudeServiceException implements Exception {
  final String message;
  const ClaudeServiceException(this.message);

  @override
  String toString() => 'ClaudeServiceException: $message';
}
