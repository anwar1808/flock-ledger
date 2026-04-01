import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:uuid/uuid.dart';
import '../../providers/chicken_provider.dart';
import '../../utils/breed_sexing_table.dart';
import '../../providers/sexing_provider.dart';
import '../../models/sexing_assessment.dart';
import '../../screens/settings/settings_screen.dart';
import '../../services/claude_service.dart';

class ChickSexingScreen extends StatefulWidget {
  /// If provided, a "Save to profile" button appears after analysis.
  final String? chickenId;

  const ChickSexingScreen({super.key, this.chickenId});

  @override
  State<ChickSexingScreen> createState() => _ChickSexingScreenState();
}

class _ChickSexingScreenState extends State<ChickSexingScreen> {
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _photos = [];
  ChickSexResult? _result;
  bool _analysing = false;
  String? _error;
  bool _errorIsAuth = false;
  int _thumbnailIndex = 0;
  String? _userGenderCall; // 'probably_female' | 'probably_male' | null

  @override
  void initState() {
    super.initState();
    // Rebuild when age changes so title/disclaimer update live
    _ageController.addListener(() => setState(() {}));
    if (widget.chickenId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chicken =
            context.read<ChickenProvider>().getById(widget.chickenId!);
        if (chicken != null) {
          if (chicken.breed != null && chicken.breed!.isNotEmpty) {
            _breedController.text = chicken.breed!;
          }
          final days = chicken.currentAgeInDays;
          if (days != null) {
            _ageController.text = (days ~/ 7).toString();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 photos')),
      );
      return;
    }
    final remaining = 8 - _photos.length;
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty && mounted) {
      final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
      setState(() => _photos.addAll(toAdd));
    }
  }

  Future<File?> _compressForApi(File source) async {
    final dir = await getTemporaryDirectory();
    final out = '${dir.path}/sex_${const Uuid().v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      source.path,
      out,
      minWidth: 1568,
      minHeight: 1568,
      quality: 82,
    );
    return result != null ? File(result.path) : null;
  }

  Future<void> _analyse() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    final apiKey = await SettingsScreen.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No API key found — add one in Settings first')),
        );
      }
      return;
    }

    setState(() {
      _analysing = true;
      _result = null;
      _error = null;
      _errorIsAuth = false;
      _thumbnailIndex = 0;
      _userGenderCall = null;
    });

    try {
      final compressed = <File>[];
      for (final photo in _photos) {
        final c = await _compressForApi(photo);
        compressed.add(c ?? photo);
      }

      final service = ClaudeService(apiKey);
      final result = await service.analyzeChickSex(
        compressed,
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        ageWeeks: int.tryParse(_ageController.text.trim()),
      );
      if (mounted) setState(() => _result = result);
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timed out — check your connection and try again.';
          _errorIsAuth = false;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _error = 'No internet connection. Please check your network and try again.';
          _errorIsAuth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isAuth = e is ClaudeServiceException && e.isAuthError;
        setState(() {
          _error = e is ClaudeServiceException
              ? e.message
              : 'Something went wrong. Please try again.';
          _errorIsAuth = isAuth;
        });
      }
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  Future<void> _saveToProfile() async {
    if (widget.chickenId == null || _result == null) return;
    final chickenProvider = context.read<ChickenProvider>();
    final sexingProvider = context.read<SexingProvider>();
    final chicken = chickenProvider.getById(widget.chickenId!);
    if (chicken == null) return;

    final gender = _userGenderCall ??
        (_result!.likelySex == 'uncertain' ? 'unknown' : _result!.likelySex);

    // Save assessment record
    final assessment = SexingAssessment(
      id: const Uuid().v4(),
      chickenId: widget.chickenId!,
      assessedAt: DateTime.now(),
      ageWeeks: int.tryParse(_ageController.text.trim()),
      claudeResult: _result!.likelySex,
      claudeConfidence: _result!.confidence,
      claudeReasoning: _result!.reasoning,
      claudeCaveats: _result!.caveats,
      userCall: _userGenderCall,
      displayedGender: gender,
    );
    await sexingProvider.addAssessment(assessment);

    final selectedPhoto = _photos.isNotEmpty ? _photos[_thumbnailIndex] : null;
    await chickenProvider.updateChicken(chicken.copyWith(
      gender: gender,
      photoPath: selectedPhoto?.path ?? chicken.photoPath,
    ));
    if (mounted) {
      final label = switch (gender) {
        'probably_female' => 'probably female',
        'probably_male' => 'probably male',
        'unknown' => 'unknown',
        _ => gender,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved — ${chicken.name} updated to $label'),
          backgroundColor: const Color(0xFF5D8A3C),
        ),
      );
      Navigator.pop(context);
    }
  }

  String? _buildFollowUpTip(ChickSexResult result, int? ageWeeks, String? breed) {
    final breedInfo = breed != null && breed.isNotEmpty
        ? lookupBreedSexingInfo(breed)
        : null;

    // Sex-linked / autosexing at hatch — no re-check needed
    if (breedInfo?.sexLinkedAtHatch == true && (ageWeeks == null || ageWeeks <= 3)) {
      return 'This breed is sex-linked — colour at hatch is definitive. No re-check needed.';
    }

    // Very difficult breeds — always give re-check guidance
    if (breedInfo?.difficulty == 'very_hard') {
      final b = breed?.toLowerCase() ?? '';
      if (b.contains('silkie') || b.contains('silky')) {
        return 'Silkies are notoriously hard to sex. Even at 8–12 weeks the result may be uncertain. '
            'Re-check at 12–16 weeks — males develop streamer crest feathers and start mounting. '
            'Crowing (3–5 months) gives a definitive answer. DNA sexing is the most reliable option before 4 months.';
      }
      if (b.contains('polish')) {
        return 'Polish are tricky as the crest obscures the comb. Re-check at 12 weeks — '
            'males develop a wilder, spikier crest while females keep a neat rounded one. '
            'Crowing (12–16 weeks) is the most reliable confirmation.';
      }
      if (b.contains('sebright')) {
        return 'Sebrights are hen-feathered — cockerels lack the pointed hackle feathers '
            'of most breeds, making visual sexing very difficult. Re-check at 12 weeks. '
            'Crowing (12–16 weeks) is the most reliable confirmation.';
      }
      final recheck = breedInfo!.earliestReliableWeeks;
      return 'This breed is difficult to sex visually before $recheck weeks. '
          'Re-check then, or wait for crowing (12–16 weeks) or first egg (18–20 weeks).';
    }

    // Low / very low confidence — always suggest re-check
    if (result.confidence == 'very_low' || result.confidence == 'low') {
      final recheckAge = (ageWeeks != null && ageWeeks < 6) ? 8 : 12;
      return 'Confidence is low — consider re-checking at $recheckAge weeks '
          'when comb and wattle differences are more pronounced.';
    }

    // Age too young for this breed
    if (ageWeeks != null && breedInfo != null &&
        ageWeeks < breedInfo.earliestReliableWeeks) {
      return 'At $ageWeeks weeks, ${breed ?? 'this breed'} is still early for reliable sexing. '
          'Re-check at ${breedInfo.earliestReliableWeeks} weeks for a more confident result.';
    }

    // Age-based generic tips
    if (ageWeeks != null) {
      if (ageWeeks < 6) {
        return 'At $ageWeeks weeks, sexing is still early for most breeds. '
            'Re-check at 8 weeks when comb and wattle differences are clearer.';
      }
      if (ageWeeks < 9) {
        return 'At $ageWeeks weeks this result should be reliable for most breeds. '
            'For extra confidence, re-check at 12 weeks when hackle and saddle feathers begin developing. '
            'Crowing (12–16 weeks) or first egg (18–20 weeks) gives a definitive answer.';
      }
      if (ageWeeks < 14) {
        return 'At $ageWeeks weeks, visual sexing should be accurate for most breeds. '
            'Crowing (12–16 weeks) or first egg (18–20 weeks) will give final confirmation.';
      }
      // 14+ weeks — result is reliable, no tip needed
      return null;
    }

    return null;
  }

  bool get _isOlderBird {
    final weeks = int.tryParse(_ageController.text.trim());
    return weeks != null && weeks >= 6;
  }

  @override
  Widget build(BuildContext context) {
    final birdTerm = _isOlderBird ? 'Sex a Pullet / Cockerel' : 'Sex a Chick';
    return Scaffold(
      appBar: AppBar(title: Text(birdTerm)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isOlderBird
                  ? 'At 6+ weeks, comb, wattle, and feathering differences are '
                    'usually clear. This should give a confident result.'
                  : 'Visual sexing is not 100% accurate, especially under 6 weeks. '
                    'This is a guide, not a guarantee.',
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Optional breed + age
          TextFormField(
            controller: _breedController,
            decoration: const InputDecoration(
              labelText: 'Breed & line (optional)',
              hintText: 'e.g. Hubbard 787, Ross 308, Silkie, RIR',
              helperText:
                  'Include the line or variety if known — it improves accuracy',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age in weeks (optional)',
              hintText: 'e.g. 6',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // Photo picker
          Text('Photos (up to 8)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._photos.asMap().entries.map((e) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(e.value,
                            width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _photos.removeAt(e.key)),
                          child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
              if (_photos.length < 8)
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text('Add',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _analysing || _photos.isEmpty ? null : _analyse,
            icon: _analysing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
            label:
                Text(_analysing ? 'Analysing...' : 'Analyse with Claude'),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer),
                  ),
                  if (_errorIsAuth) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Go to Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onErrorContainer,
                        side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer
                                .withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Thumbnail picker (shown after analysis when saving is possible)
          if (_result != null && widget.chickenId != null && _photos.length > 1) ...[
            const SizedBox(height: 24),
            Text('Profile photo',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Tap a photo to use it as this bird\'s profile picture',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _photos.asMap().entries.map((e) {
                final selected = e.key == _thumbnailIndex;
                return GestureDetector(
                  onTap: () => setState(() => _thumbnailIndex = e.key),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(e.value,
                            width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      if (selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // "Your call" override — shown for moderate/low/very_low confidence
          if (_result != null &&
              (_result!.confidence == 'moderate' ||
                  _result!.confidence == 'low' ||
                  _result!.confidence == 'very_low')) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline,
                          size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Not confident — make your call',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CallChip(
                        label: 'Probably female',
                        symbol: '♀',
                        color: const Color(0xFFE91E8C),
                        selected: _userGenderCall == 'probably_female',
                        onTap: () => setState(() {
                          _userGenderCall =
                              _userGenderCall == 'probably_female'
                                  ? null
                                  : 'probably_female';
                        }),
                      ),
                      const SizedBox(width: 10),
                      _CallChip(
                        label: 'Probably male',
                        symbol: '♂',
                        color: const Color(0xFF4A90D9),
                        selected: _userGenderCall == 'probably_male',
                        onTap: () => setState(() {
                          _userGenderCall =
                              _userGenderCall == 'probably_male'
                                  ? null
                                  : 'probably_male';
                        }),
                      ),
                    ],
                  ),
                  if (_userGenderCall != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your call will be saved instead of Claude\'s result.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade800),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Result
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(
              result: _result!,
              onSave: widget.chickenId != null ? _saveToProfile : null,
            ),
            // Follow-up tip
            Builder(builder: (context) {
              final tip = _buildFollowUpTip(
                _result!,
                int.tryParse(_ageController.text.trim()),
                _breedController.text.trim().isNotEmpty
                    ? _breedController.text.trim()
                    : null,
              );
              if (tip == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Result card ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final ChickSexResult result;
  final VoidCallback? onSave;

  const _ResultCard({required this.result, this.onSave});

  @override
  Widget build(BuildContext context) {
    final sexLabel = switch (result.likelySex) {
      'female' => 'Likely Female',
      'male' => 'Likely Male',
      _ => 'Uncertain',
    };
    final sexIcon = switch (result.likelySex) {
      'female' => '♀',
      'male' => '♂',
      _ => '?',
    };
    final sexColor = switch (result.likelySex) {
      'female' => const Color(0xFFE91E8C),
      'male' => const Color(0xFF4A90D9),
      _ => Colors.grey,
    };

    final confidenceLabel = switch (result.confidence) {
      'very_high' => 'Very high confidence',
      'high'      => 'High confidence',
      'moderate'  => 'Moderate confidence',
      'low'       => 'Low confidence',
      _           => 'Very low confidence',
    };
    final confidenceColor = switch (result.confidence) {
      'very_high' => const Color(0xFF2E7D32),
      'high'      => const Color(0xFF5D8A3C),
      'moderate'  => const Color(0xFFD4A017),
      'low'       => Colors.deepOrange.shade600,
      _           => Colors.red.shade700,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sexIcon,
                    style:
                        TextStyle(fontSize: 32, color: sexColor)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sexLabel,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: sexColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        confidenceLabel,
                        style: TextStyle(
                            color: confidenceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(result.reasoning,
                style: const TextStyle(fontSize: 14)),
            if (result.caveats != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(result.caveats!,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900)),
                    ),
                  ],
                ),
              ),
            ],
            if (onSave != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save gender to profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Call chip ────────────────────────────────────────────────────────────────

class _CallChip extends StatelessWidget {
  final String label;
  final String symbol;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CallChip({
    required this.label,
    required this.symbol,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol,
                style: TextStyle(
                    fontSize: 16,
                    color: selected ? color : Colors.grey.shade500)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
