import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../providers/egg_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../models/egg_record.dart';
import '../../models/chicken.dart';
import '../../services/claude_service.dart';
import '../../utils/date_parser.dart';
import '../../utils/egg_color_matcher.dart';
import '../settings/settings_screen.dart';

/// Represents one photo in the batch-review queue.
class _PhotoJob {
  final File originalFile;
  File? storedFile; // compressed for storage
  File? apiFile; // smaller compressed for Claude

  DateTime date;
  double? weightGrams;
  String eggColorCategory;
  String? suggestedChickenId;
  String? selectedChickenId;

  bool analyzing;
  bool analyzed;
  String? errorMessage;

  _PhotoJob({
    required this.originalFile,
    required this.date,
    this.weightGrams,
    this.eggColorCategory = 'unknown',
    this.analyzing = false,
    this.analyzed = false,
    this.errorMessage,
  });
}

class EggCaptureScreen extends StatefulWidget {
  final EggRecord? existingRecord; // non-null → editing a single existing record

  const EggCaptureScreen({super.key, this.existingRecord});

  @override
  State<EggCaptureScreen> createState() => _EggCaptureScreenState();
}

class _EggCaptureScreenState extends State<EggCaptureScreen> {
  final List<_PhotoJob> _jobs = [];
  bool _loadingPhotos = false;
  bool _saving = false;

  // For editing an existing record
  bool get _isEditing => widget.existingRecord != null;
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _editDate = DateTime.now();
  String _editColor = 'unknown';
  String? _editChickenId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final r = widget.existingRecord!;
      _weightController.text = r.weightGrams.toStringAsFixed(1);
      _notesController.text = r.notes ?? '';
      _editDate = r.date;
      _editColor = r.eggColorCategory;
      _editChickenId = r.chickenId;
    } else {
      // Auto-open photo picker on first load
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhotos());
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    setState(() => _loadingPhotos = true);
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) {
      if (mounted) setState(() => _loadingPhotos = false);
      return;
    }

    // Get API key
    final apiKey = await SettingsScreen.getApiKey();

    for (final img in picked) {
      final file = File(img.path);

      // Parse date from filename / EXIF
      final parsedDate = await parseDateFromPhoto(file);
      final job = _PhotoJob(
        originalFile: file,
        date: parsedDate ?? DateTime.now(),
        analyzing: apiKey != null,
      );

      if (mounted) setState(() => _jobs.add(job));

      // Compress for storage
      final storedPath = await _compressForStorage(img.path);
      final apiPath = await _compressForApi(img.path);

      if (storedPath != null) job.storedFile = File(storedPath);
      if (apiPath != null) job.apiFile = File(apiPath);

      // Call Claude if we have a key
      if (apiKey != null && job.apiFile != null) {
        try {
          final service = ClaudeService(apiKey);
          final result = await service.analyzeEggPhoto(job.apiFile!);

          // Auto-match chicken by egg colour
          if (mounted) {
            final chickens =
                context.read<ChickenProvider>().activeChickens;
            final matches =
                matchChickensByEggColor(chickens, result.eggColorCategory);

            job.weightGrams = result.weightGrams;
            job.eggColorCategory = result.eggColorCategory;
            job.analyzing = false;
            job.analyzed = true;

            if (matches.length == 1) {
              job.suggestedChickenId = matches.first.id;
              job.selectedChickenId = matches.first.id;
            } else if (matches.isEmpty) {
              job.suggestedChickenId = null;
              job.selectedChickenId = null;
            } else {
              // Multiple matches → leave unset, user will choose
              job.suggestedChickenId = null;
              job.selectedChickenId = null;
            }

            if (result.weightGrams == null) {
              job.errorMessage =
                  'The scale wasn\'t clear in that photo — tap to enter the weight yourself';
            }
          }
        } catch (e) {
          job.errorMessage =
              'Couldn\'t analyse this photo — tap to enter the details yourself';
          job.analyzing = false;
          job.analyzed = true;
        }
      } else {
        job.analyzing = false;
        job.analyzed = true;
        if (apiKey == null) {
          job.errorMessage = 'No API key set — enter the weight manually';
        }
      }

      if (mounted) setState(() {});
    }

    if (mounted) setState(() => _loadingPhotos = false);
  }

  Future<String?> _compressForStorage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = '${dir.path}/egg_${const Uuid().v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      out,
      minWidth: 1200,
      minHeight: 1200,
      quality: 82,
    );
    return result?.path;
  }

  Future<String?> _compressForApi(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final out = '${dir.path}/api_${const Uuid().v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      out,
      minWidth: 1024,
      minHeight: 1024,
      quality: 70,
    );
    return result?.path;
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final eggProvider = context.read<EggProvider>();

    for (final job in _jobs) {
      if (job.weightGrams == null) continue; // skip if no weight
      await eggProvider.addRecord(
        chickenId: job.selectedChickenId,
        weightGrams: job.weightGrams!,
        eggColorCategory: job.eggColorCategory,
        date: job.date,
        photoPath: job.storedFile?.path,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveEdit() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }
    setState(() => _saving = true);
    final r = widget.existingRecord!;
    await context.read<EggProvider>().updateRecord(
          r.copyWith(
            chickenId: _editChickenId,
            weightGrams: weight,
            eggColorCategory: _editColor,
            date: _editDate,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteEdit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this egg record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<EggProvider>().deleteRecord(widget.existingRecord!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) return _buildEditView(context);
    return _buildCaptureView(context);
  }

  // ─────── EDIT existing record ───────
  Widget _buildEditView(BuildContext context) {
    final chickens = context.watch<ChickenProvider>().activeChickens;
    final record = widget.existingRecord!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Egg Record'),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _deleteEdit),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (record.photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(record.photoPath!),
                  height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle:
                Text(DateFormat('d MMMM yyyy').format(_editDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _editDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _editDate = picked);
            },
          ),
          const SizedBox(height: 12),

          // Weight
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (grams)',
              suffixText: 'g',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Egg colour
          Text('Egg Colour',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kEggColorCategories.map((cat) {
              final sel = _editColor == cat;
              return GestureDetector(
                onTap: () => setState(() => _editColor = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: eggColorSwatch(cat),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel ? Colors.black : Colors.grey.shade300,
                        width: sel ? 2 : 1),
                  ),
                  child: Text(
                    kEggColorLabels[cat] ?? cat,
                    style: TextStyle(
                        fontSize: 11, color: eggColorTextColor(cat)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Chicken
          DropdownButtonFormField<String?>(
            value: _editChickenId,
            decoration: const InputDecoration(labelText: 'Laid by'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Unassigned')),
              ...chickens.map((c) =>
                  DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _editChickenId = v),
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving ? null : _saveEdit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ─────── CAPTURE new records ───────
  Widget _buildCaptureView(BuildContext context) {
    final allSaved = _jobs.isNotEmpty &&
        _jobs.every((j) => j.analyzed && j.weightGrams != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_jobs.isEmpty ? 'Add Eggs' : '${_jobs.length} photo(s)'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('More'),
            onPressed: _loadingPhotos ? null : _pickPhotos,
          ),
        ],
      ),
      body: _jobs.isEmpty
          ? Center(
              child: _loadingPhotos
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Select photos to get started',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Choose photos'),
                          onPressed: _pickPhotos,
                        ),
                      ],
                    ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _jobs.length,
              itemBuilder: (context, index) => _JobCard(
                job: _jobs[index],
                onChanged: () => setState(() {}),
              ),
            ),
      bottomNavigationBar: _jobs.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: (_saving || !allSaved) ? null : _saveAll,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Save ${_jobs.where((j) => j.weightGrams != null).length} egg(s)'),
                ),
              ),
            )
          : null,
    );
  }
}

/// A card showing one photo job in the review queue.
class _JobCard extends StatefulWidget {
  final _PhotoJob job;
  final VoidCallback onChanged;

  const _JobCard({required this.job, required this.onChanged});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  late TextEditingController _weightCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.job.weightGrams?.toStringAsFixed(1) ?? '');
    // Auto-expand if there's an error or missing weight
    _expanded = widget.job.errorMessage != null ||
        widget.job.weightGrams == null;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final chickens =
        context.watch<ChickenProvider>().activeChickens;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with photo thumbnail
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    job.storedFile ?? job.originalFile,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job.analyzing)
                        const Row(
                          children: [
                            SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Analysing photo...',
                                style: TextStyle(fontSize: 13)),
                          ],
                        )
                      else if (job.weightGrams != null) ...[
                        Text(
                          '${job.weightGrams!.toStringAsFixed(1)}g',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: eggColorSwatch(job.eggColorCategory),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              kEggColorLabels[job.eggColorCategory] ??
                                  job.eggColorCategory,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text('Weight needed',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500)),
                      ],
                      if (job.errorMessage != null)
                        Text(
                          job.errorMessage!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange),
                          maxLines: 2,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Date',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                        DateFormat('d MMM yyyy').format(job.date),
                        style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.calendar_today_outlined,
                        size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: job.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => job.date = picked);
                        widget.onChanged();
                      }
                    },
                  ),

                  // Weight override
                  TextField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Weight (g)',
                      suffixText: 'g',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      job.weightGrams = parsed;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Egg colour
                  Text('Egg Colour',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kEggColorCategories.map((cat) {
                      final sel = job.eggColorCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() => job.eggColorCategory = cat);
                          widget.onChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: eggColorSwatch(cat),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: sel
                                    ? Colors.black
                                    : Colors.grey.shade300,
                                width: sel ? 2 : 1),
                          ),
                          child: Text(
                            kEggColorLabels[cat] ?? cat,
                            style: TextStyle(
                                fontSize: 10,
                                color: eggColorTextColor(cat)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Chicken picker
                  DropdownButtonFormField<String?>(
                    value: job.selectedChickenId,
                    decoration: const InputDecoration(
                      labelText: 'Laid by',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Unassigned')),
                      ...chickens.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                if (c.eggColorCategory != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(right: 6),
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: eggColorSwatch(
                                            c.eggColorCategory!),
                                      ),
                                    ),
                                  ),
                                Text(c.name),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => job.selectedChickenId = v);
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
