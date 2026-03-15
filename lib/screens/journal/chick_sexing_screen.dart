import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/chicken_provider.dart';
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

  @override
  void initState() {
    super.initState();
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
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos')),
      );
      return;
    }
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _photos.add(File(picked.path)));
    }
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
    });

    try {
      final service = ClaudeService(apiKey);
      final result = await service.analyzeChickSex(
        _photos,
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        ageWeeks: int.tryParse(_ageController.text.trim()),
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  Future<void> _saveToProfile() async {
    if (widget.chickenId == null || _result == null) return;
    final provider = context.read<ChickenProvider>();
    final chicken = provider.getById(widget.chickenId!);
    if (chicken == null) return;

    final gender = _result!.likelySex == 'uncertain'
        ? 'unknown'
        : _result!.likelySex;

    await provider.updateChicken(chicken.copyWith(gender: gender));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Saved — ${chicken.name} updated to ${gender == 'unknown' ? 'unknown' : gender}'),
          backgroundColor: const Color(0xFF5D8A3C),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sex a Chick')),
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
              'Visual sexing is not 100% accurate, especially under 6 weeks. '
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
              labelText: 'Breed (optional)',
              hintText: 'e.g. Silkie, Rhode Island Red',
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
          Text('Photos (up to 4)',
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
              if (_photos.length < 4)
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
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer)),
            ),
          ],

          // Result
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(
              result: _result!,
              onSave: widget.chickenId != null ? _saveToProfile : null,
            ),
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

    final confidenceColor = switch (result.confidence) {
      'high' => const Color(0xFF5D8A3C),
      'medium' => const Color(0xFFD4A017),
      _ => Colors.grey,
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
                        '${result.confidence[0].toUpperCase()}${result.confidence.substring(1)} confidence',
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
