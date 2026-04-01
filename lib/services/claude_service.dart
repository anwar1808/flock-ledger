import 'dart:async';
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

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw ClaudeServiceException._fromStatus(response.statusCode);
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (responseData['content'] as List).first;
    final text = (content as Map<String, dynamic>)['text'] as String;

    // Extract JSON from the response (Claude should return only JSON)
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) {
      throw ClaudeServiceException(
          'Could not parse response from Claude. Please try again.');
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

    final isOlderBird = ageWeeks != null && ageWeeks >= 6;
    final birdTerm = isOlderBird ? 'pullet/cockerel' : 'chick';
    final birdTermPlural = isOlderBird ? 'pullets/cockerels' : 'chicks';

    final breedNote = breed != null && breed.isNotEmpty
        ? 'Breed: $breed.\n'
        : '';
    final ageNote = ageWeeks != null
        ? 'Age: approximately $ageWeeks weeks old.\n'
        : '';

    // Age-calibrated guidance for the prompt
    String ageGuidance;
    if (ageWeeks == null) {
      ageGuidance = '''Age unknown — assess based on visible development stage.
- If clearly very young (heavy down, no comb): expect low confidence
- If feathered with visible comb: apply 6+ week guidance below''';
    } else if (ageWeeks < 4) {
      ageGuidance = '''At under 4 weeks, visual sexing is very difficult in most breeds.
- Comb differences are minimal and unreliable at this age
- Feather sexing (if applicable) is the most reliable cue — females feather faster in sex-linked breeds
- Be honest about uncertainty — low or medium confidence is appropriate unless feather sexing applies''';
    } else if (ageWeeks < 6) {
      ageGuidance = '''At 4–5 weeks, early comb differences are starting to emerge in some breeds.
- Males may show a slightly larger, pinker comb but differences are often subtle
- Fast, even feathering = more likely female in many breeds; patchy/slow = more likely male
- Medium confidence is appropriate unless comb difference is pronounced''';
    } else if (ageWeeks < 10) {
      ageGuidance = '''At 6–9 weeks, secondary sex characteristics are clearly developing.
- Males: noticeably larger and redder comb, early wattle buds, often larger body frame, coarser feathering
- Females: small flat comb, no wattle development, finer feathering, typically smaller frame
- When multiple cues agree, HIGH confidence is appropriate — do not hedge if the evidence is clear
- Commercial broiler crosses (Hubbard, Ross, Cobb): males also show significantly faster weight gain and larger frame by this age''';
    } else {
      ageGuidance = '''At 10+ weeks, sexing should be definitive in almost all breeds.
- Cockerels: prominent comb and wattles (red and developed), pointed hackle and saddle feathers beginning, larger body
- Pullets: small pale comb, no wattles, rounded feathering, smaller frame
- HIGH confidence is expected unless the breed is genuinely difficult (e.g. Silkies, some Sebrights)
- If you cannot determine sex at this age, explain exactly why in the reasoning''';
    }

    imageContents.add({
      'type': 'text',
      'text': '''${breedNote}${ageNote}
$ageGuidance

Assess the sex of the $birdTerm shown in these photos. Evaluate each cue systematically before giving your verdict:
1. Comb — size, colour, development
2. Wattles — present or absent, size
3. Body size and frame
4. Feather development and texture (hackle, saddle if visible)
5. Overall impression

Return ONLY valid JSON (no other text):
{
  "likely_sex": "female",
  "confidence": "high",
  "reasoning": "Comb is small and pale with no wattle development. Feathering is fine and even. Body frame is noticeably smaller than siblings. All cues consistently point to pullet.",
  "caveats": "Silkies are notoriously difficult to sex before 4–5 months — treat this as a rough guide only."
}

Rules:
- likely_sex must be exactly "female", "male", or "uncertain"
- confidence must be "high" when two or more cues clearly agree; "medium" when cues are mixed or subtle; "low" when genuinely unclear
- Do not default to "medium" as a safe hedge — commit to "high" when the evidence warrants it
- reasoning should be 2–4 sentences covering the specific cues you observed
- caveats is optional — only include if there is a genuine breed-specific or age-specific caveat; omit otherwise
- If multiple $birdTermPlural are shown, give the most common assessment and note any variation''',
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

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw ClaudeServiceException._fromStatus(response.statusCode);
    }

    final responseData =
        jsonDecode(response.body) as Map<String, dynamic>;
    final content = (responseData['content'] as List).first;
    final text = (content as Map<String, dynamic>)['text'] as String;

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch == null) {
      throw ClaudeServiceException(
          'Could not parse response from Claude. Please try again.');
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
  /// True when the error is caused by an invalid or missing API key (HTTP 401).
  final bool isAuthError;

  const ClaudeServiceException(this.message, {this.isAuthError = false});

  factory ClaudeServiceException._fromStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return const ClaudeServiceException(
          'Invalid API key — please update it in Settings.',
          isAuthError: true,
        );
      case 429:
        return const ClaudeServiceException(
          'Rate limit reached. Please wait a moment and try again.',
        );
      case 500:
      case 502:
      case 503:
        return const ClaudeServiceException(
          'The Anthropic service is temporarily unavailable. Please try again shortly.',
        );
      default:
        return ClaudeServiceException(
          'Something went wrong (error $statusCode). Please try again.',
        );
    }
  }

  @override
  String toString() => message;
}
