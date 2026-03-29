import 'dart:convert';
import 'package:http/http.dart' as http;

class BreedIncubationInfo {
  final int days;
  final String species;
  final String? note;

  const BreedIncubationInfo({
    required this.days,
    required this.species,
    this.note,
  });
}

// ─── Obfuscated bundled API key ──────────────────────────────────────────────
// Split across three constants so the key never appears as a single plain-text
// string in the compiled APK (stops casual extraction with apktool/jadx).
//
// ⚠️  FILL IN: take your sk-ant-... key and split it into three chunks.
//     e.g. "sk-ant-api03-AAABBBCCC" → _kp1='sk-ant-', _kp2='api03-AAA', _kp3='BBBCCC'
//     Then set a spend cap on this key in console.anthropic.com.
const _kp1 = 'sk-ant-api03-CeFCOZxPNzE7TAr1hvx';
const _kp2 = 'wVa9DFzHkQKmPPLcEwaVfvPd_upLhLYa_f4';
const _kp3 = 'obnfs5ux5IUAaIqh6eUbTICNIa7TCZSA-tmSc7QAA';
String get _bundledKey => _kp1 + _kp2 + _kp3;

// ─── Local breed table ───────────────────────────────────────────────────────
// Keyed by lowercase normalised breed name. Covers ~50 common breeds/aliases.
const Map<String, BreedIncubationInfo> _kTable = {
  // ── Chickens — 21 days ──────────────────────────────────────────────────
  'silkie': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'silky': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'sussex': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'light sussex': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'speckled sussex': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'leghorn': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'rhode island red': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'rir': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'plymouth rock': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'barred rock': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'wyandotte': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'orpington': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'buff orpington': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'marans': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'black copper marans': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'australorp': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'black australorp': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'barnevelder': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'brahma': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'light brahma': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'dark brahma': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'buff brahma': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'cochin': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'jersey giant': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'new hampshire': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'new hampshire red': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'welsummer': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'ancona': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'hamburg': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'easter egger': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'ameraucana': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'araucana': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'faverolles': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'salmon faverolles': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'dominique': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'langshan': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'minorca': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'polish': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'isa brown': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'hy-line': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'hyline': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'hybrid': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'mixed': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'mixed breed': BreedIncubationInfo(days: 21, species: 'Chicken'),
  'heritage': BreedIncubationInfo(days: 21, species: 'Chicken'),
  // ── Ducks ────────────────────────────────────────────────────────────────
  'pekin': BreedIncubationInfo(days: 28, species: 'Duck'),
  'pekin duck': BreedIncubationInfo(days: 28, species: 'Duck'),
  'mallard': BreedIncubationInfo(days: 28, species: 'Duck'),
  'khaki campbell': BreedIncubationInfo(days: 28, species: 'Duck'),
  'campbell': BreedIncubationInfo(days: 28, species: 'Duck'),
  'indian runner': BreedIncubationInfo(days: 28, species: 'Duck'),
  'runner duck': BreedIncubationInfo(days: 28, species: 'Duck'),
  'cayuga': BreedIncubationInfo(days: 28, species: 'Duck'),
  'rouen': BreedIncubationInfo(days: 28, species: 'Duck'),
  'aylesbury': BreedIncubationInfo(days: 28, species: 'Duck'),
  'swedish': BreedIncubationInfo(days: 28, species: 'Duck'),
  'blue swedish': BreedIncubationInfo(days: 28, species: 'Duck'),
  'muscovy': BreedIncubationInfo(days: 35, species: 'Muscovy Duck'),
  'muscovy duck': BreedIncubationInfo(days: 35, species: 'Muscovy Duck'),
  // ── Turkeys ──────────────────────────────────────────────────────────────
  'turkey': BreedIncubationInfo(days: 28, species: 'Turkey'),
  'broad breasted white': BreedIncubationInfo(days: 28, species: 'Turkey'),
  'broad breasted bronze': BreedIncubationInfo(days: 28, species: 'Turkey'),
  'bourbon red': BreedIncubationInfo(days: 28, species: 'Turkey'),
  'narragansett': BreedIncubationInfo(days: 28, species: 'Turkey'),
  'heritage turkey': BreedIncubationInfo(days: 28, species: 'Turkey'),
  // ── Guinea Fowl ──────────────────────────────────────────────────────────
  'guinea fowl': BreedIncubationInfo(days: 28, species: 'Guinea Fowl'),
  'guinea': BreedIncubationInfo(days: 28, species: 'Guinea Fowl'),
  'helmeted guinea': BreedIncubationInfo(days: 28, species: 'Guinea Fowl'),
  // ── Quail ─────────────────────────────────────────────────────────────────
  'coturnix': BreedIncubationInfo(days: 17, species: 'Quail'),
  'coturnix quail': BreedIncubationInfo(days: 17, species: 'Quail'),
  'japanese quail': BreedIncubationInfo(days: 17, species: 'Quail'),
  'bobwhite': BreedIncubationInfo(days: 23, species: 'Quail'),
  'bobwhite quail': BreedIncubationInfo(days: 23, species: 'Quail'),
  'button quail': BreedIncubationInfo(days: 16, species: 'Quail'),
  'king quail': BreedIncubationInfo(days: 16, species: 'Quail'),
  // ── Geese ─────────────────────────────────────────────────────────────────
  'goose': BreedIncubationInfo(days: 30, species: 'Goose'),
  'embden': BreedIncubationInfo(days: 30, species: 'Goose'),
  'toulouse': BreedIncubationInfo(days: 30, species: 'Goose'),
  'chinese goose': BreedIncubationInfo(days: 30, species: 'Goose'),
  'african goose': BreedIncubationInfo(days: 30, species: 'Goose'),
  'pilgrim goose': BreedIncubationInfo(days: 30, species: 'Goose'),
  // ── Pheasant / Peafowl ────────────────────────────────────────────────────
  'pheasant': BreedIncubationInfo(days: 24, species: 'Pheasant'),
  'ring-necked pheasant': BreedIncubationInfo(days: 24, species: 'Pheasant'),
  'ringneck pheasant': BreedIncubationInfo(days: 24, species: 'Pheasant'),
  'peacock': BreedIncubationInfo(days: 28, species: 'Peafowl'),
  'peafowl': BreedIncubationInfo(days: 28, species: 'Peafowl'),
  'peahen': BreedIncubationInfo(days: 28, species: 'Peafowl'),
};

// ─── Local lookup ────────────────────────────────────────────────────────────

/// Looks up the breed in the local table. Case-insensitive.
/// Returns null if not found — caller should then try [lookupBreedIncubation].
BreedIncubationInfo? lookupBreedLocally(String breed) {
  final key = breed.toLowerCase().trim();
  if (_kTable.containsKey(key)) return _kTable[key];
  // Partial / contained match
  for (final entry in _kTable.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) {
      return entry.value;
    }
  }
  return null;
}

// ─── Full async lookup (local → Claude fallback) ─────────────────────────────

/// Returns incubation info for [breed].
/// Tries the local table first (instant, no cost). If not found, calls
/// Claude using [userApiKey] if set, otherwise the bundled key.
Future<BreedIncubationInfo> lookupBreedIncubation(
  String breed, {
  String? userApiKey,
}) async {
  final local = lookupBreedLocally(breed);
  if (local != null) return local;

  // Prefer user's own key; fall back to bundled key
  final apiKey =
      (userApiKey != null && userApiKey.trim().isNotEmpty) ? userApiKey : _bundledKey;

  try {
    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 128,
            'messages': [
              {
                'role': 'user',
                'content':
                    'What is the standard egg incubation period in days for this poultry breed: "$breed"?\n\n'
                    'Return ONLY valid JSON with no other text:\n'
                    '{"days": 21, "species": "Chicken", "note": null}\n\n'
                    'Rules:\n'
                    '- days must be an integer\n'
                    '- species is the common animal type (Chicken, Duck, Turkey, Quail, etc.)\n'
                    '- note is a short string for unusual cases, or null\n'
                    '- If you do not recognise the breed, return {"days": 21, "species": "Unknown", "note": "Breed not recognised — defaulting to 21 days"}',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          ((data['content'] as List).first as Map<String, dynamic>)['text']
              as String;
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(text);
      if (jsonMatch != null) {
        final parsed =
            jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return BreedIncubationInfo(
          days: (parsed['days'] as num?)?.toInt() ?? 21,
          species: (parsed['species'] as String?) ?? 'Unknown',
          note: parsed['note'] as String?,
        );
      }
    }
  } catch (_) {
    // Network error, timeout, parse failure — fall through to default
  }

  return const BreedIncubationInfo(
    days: 21,
    species: 'Unknown',
    note: 'Could not look up breed — defaulting to 21 days',
  );
}
