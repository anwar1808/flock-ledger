import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/egg_grade_standard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const _storage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'anthropic_api_key';

  /// Readable from any screen — loads the saved API key.
  static Future<String?> getApiKey() async {
    return _storage.read(key: _apiKeyStorageKey);
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'anthropic_api_key';

  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _saving = false;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _storage.read(key: _apiKeyStorageKey);
    if (key != null && mounted) {
      setState(() {
        _apiKeyController.text = key;
        _keySaved = true;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _saving = true);
    await _storage.write(key: _apiKeyStorageKey, value: key);
    if (mounted) {
      setState(() {
        _saving = false;
        _keySaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved securely'),
          backgroundColor: Color(0xFF5D8A3C),
        ),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
    if (mounted) {
      setState(() {
        _apiKeyController.clear();
        _keySaved = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── API Key Section ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Anthropic API Key',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_keySaved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D8A3C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Saved',
                              style: TextStyle(
                                  color: Color(0xFF5D8A3C), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your API key is stored securely on this device and never sent anywhere except directly to Anthropic when you analyse an egg photo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'sk-ant-...',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureKey ? Icons.visibility : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _saving ? null : _saveApiKey,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save Key'),
                      ),
                      if (_keySaved) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearApiKey,
                          child: const Text('Remove'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Visit console.anthropic.com to get your API key'),
                        ),
                      );
                    },
                    child: const Text(
                      'Get an API key at console.anthropic.com →',
                      style: TextStyle(
                        color: Color(0xFF5D8A3C),
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Egg Settings ───
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.egg_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text('Egg Settings',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grading standard
                      Text('Size Grading Standard',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Grades are computed from raw weights — '
                        'switching standard re-grades all your data instantly.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<EggGradeStandard>(
                        segments: EggGradeStandard.values
                            .map((s) => ButtonSegment(
                                  value: s,
                                  label: Text(EggGradeHelper.standardName(s)),
                                ))
                            .toList(),
                        selected: {settings.gradingStandard},
                        onSelectionChanged: (s) =>
                            settings.setGradingStandard(s.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.gradingStandard == EggGradeStandard.ukEu
                            ? 'S <53 g · M 53–63 g · L 63–73 g · XL ≥73 g'
                            : 'Peewee <42 g · Small 42–49 g · Med 49–56 g · '
                                'Large 56–63 g · XL 63–70 g · Jumbo ≥70 g',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 11),
                      ),
                      const SizedBox(height: 20),

                      // Weight unit
                      Text('Weight Unit',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Raw weights are always stored in grams. '
                        'Changing unit re-displays all values — no data is lost.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<WeightUnit>(
                        segments: const [
                          ButtonSegment(
                              value: WeightUnit.grams, label: Text('g (grams)')),
                          ButtonSegment(
                              value: WeightUnit.oz, label: Text('oz (ounces)')),
                        ],
                        selected: {settings.weightUnit},
                        onSelectionChanged: (s) =>
                            settings.setWeightUnit(s.first),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ─── About Section ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'FlockLedger — a personal app for raising and tracking your flock.\n\nEgg weights are read by Claude (claude-opus-4-6) with your own API key. Each photo costs a fraction of a cent.'),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
