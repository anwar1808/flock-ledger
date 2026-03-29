import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../providers/chicken_provider.dart';
import '../../models/chicken.dart';
import '../../utils/egg_color_matcher.dart';

class ChickenEditScreen extends StatefulWidget {
  final Chicken? chicken; // null → adding new

  const ChickenEditScreen({super.key, this.chicken});

  @override
  State<ChickenEditScreen> createState() => _ChickenEditScreenState();
}

class _ChickenEditScreenState extends State<ChickenEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _hatchDate;
  String? _photoPath;
  String? _eggColorCategory;
  String? _flockGroupId;
  String _gender = 'unknown';
  String _acquiredVia = 'hatched';
  DateTime? _buyDate;
  final _ageAtPurchaseController = TextEditingController();
  List<String> _samplePhotos = [];
  String _status = 'active';
  DateTime? _statusDate;
  final _statusNoteController = TextEditingController();
  String _purpose = 'layer';
  final _liveWeightController = TextEditingController();
  final _dressedWeightController = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.chicken != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.chicken!;
      _nameController.text = c.name;
      _breedController.text = c.breed ?? '';
      _colorController.text = c.color ?? '';
      _notesController.text = c.notes ?? '';
      _hatchDate = c.hatchDate;
      _photoPath = c.photoPath;
      _eggColorCategory = c.eggColorCategory;
      _samplePhotos = List.from(c.eggSamplePhotos);
      _status = c.status;
      _statusDate = c.statusDate;
      _statusNoteController.text = c.statusNote ?? '';
      _flockGroupId = c.flockGroupId;
      _gender = c.gender;
      _acquiredVia = c.acquiredVia;
      _buyDate = c.buyDate;
      _ageAtPurchaseController.text =
          c.ageAtPurchaseWeeks?.toString() ?? '';
      _purpose = c.purpose;
      _liveWeightController.text =
          c.liveWeightGrams?.toStringAsFixed(1) ?? '';
      _dressedWeightController.text =
          c.dressedWeightGrams?.toStringAsFixed(1) ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _ageAtPurchaseController.dispose();
    _statusNoteController.dispose();
    _liveWeightController.dispose();
    _dressedWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final compressed = await _compressImage(picked.path, prefix: 'chicken');
    if (compressed != null && mounted) {
      setState(() => _photoPath = compressed);
    }
  }

  Future<void> _pickSampleEggPhoto() async {
    if (_samplePhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 3 sample egg photos')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final compressed = await _compressImage(picked.path, prefix: 'egg_sample');
    if (compressed != null && mounted) {
      setState(() => _samplePhotos.add(compressed));
    }
  }

  Future<String?> _compressImage(String sourcePath,
      {required String prefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath =
        '${dir.path}/${prefix}_${const Uuid().v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      outPath,
      minWidth: 1200,
      minHeight: 1200,
      quality: 82,
    );
    return result?.path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ChickenProvider>();

    final ageWeeks =
        int.tryParse(_ageAtPurchaseController.text.trim());

    final liveW = double.tryParse(_liveWeightController.text.trim());
    final dressedW = double.tryParse(_dressedWeightController.text.trim());

    if (_isEditing) {
      final updated = widget.chicken!.copyWith(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        hatchDate: _acquiredVia == 'hatched' ? _hatchDate : null,
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        photoPath: _photoPath,
        eggColorCategory: _eggColorCategory,
        eggSamplePhotos: _samplePhotos,
        status: _status,
        statusDate: _status != 'active' ? _statusDate : null,
        statusNote: _status != 'active' &&
                _statusNoteController.text.trim().isNotEmpty
            ? _statusNoteController.text.trim()
            : null,
        flockGroupId: _flockGroupId,
        gender: _gender,
        acquiredVia: _acquiredVia,
        buyDate: _acquiredVia == 'bought' ? _buyDate : null,
        ageAtPurchaseWeeks:
            _acquiredVia == 'bought' ? ageWeeks : null,
        purpose: _purpose,
        liveWeightGrams: liveW,
        dressedWeightGrams: dressedW,
      );
      await provider.updateChicken(updated);
    } else {
      await provider.addChicken(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        hatchDate: _acquiredVia == 'hatched' ? _hatchDate : null,
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        photoPath: _photoPath,
        eggColorCategory: _eggColorCategory,
        eggSamplePhotos: _samplePhotos,
        flockGroupId: _flockGroupId,
        gender: _gender,
        acquiredVia: _acquiredVia,
        buyDate: _acquiredVia == 'bought' ? _buyDate : null,
        ageAtPurchaseWeeks:
            _acquiredVia == 'bought' ? ageWeeks : null,
        purpose: _purpose,
        liveWeightGrams: liveW,
        dressedWeightGrams: dressedW,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _createGroupInline(
      BuildContext context, ChickenProvider provider) async {
    final controller = TextEditingController();
    final newGroup = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New flock group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Main Flock, Bantam Run',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );

    if (newGroup == null || newGroup.isEmpty) return;
    final group = await provider.addFlockGroup(
      name: newGroup,
      colorHex: '#5D8A3C',
    );
    if (mounted) setState(() => _flockGroupId = group.id);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this hen?'),
        content: const Text(
            'This will remove her profile. Her egg records will remain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<ChickenProvider>()
          .deleteChicken(widget.chicken!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${widget.chicken!.name}' : 'Add a Chicken'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _photoPath != null
                      ? Stack(
                          children: [
                            Image.file(File(_photoPath!),
                                width: 120, height: 120, fit: BoxFit.cover),
                            // Camera affordance overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                ),
                                child: const Center(
                                  child: Icon(Icons.camera_alt_outlined,
                                      size: 28, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text('Add photo',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 12),

            // Breed (free text)
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g. Silkie, RIR × Australorp cross',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Flock group
            Consumer<ChickenProvider>(
              builder: (context, provider, _) {
                final groups = provider.flockGroups;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _flockGroupId,
                            decoration: const InputDecoration(
                                labelText: 'Flock group'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Ungrouped'),
                              ),
                              ...groups.map((g) {
                                final hex =
                                    g.colorHex.replaceAll('#', '');
                                final color = Color(
                                    int.parse('FF$hex', radix: 16));
                                return DropdownMenuItem<String?>(
                                  value: g.id,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                          radius: 6,
                                          backgroundColor: color),
                                      const SizedBox(width: 8),
                                      Text(g.name),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _flockGroupId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton.filled(
                            icon: const Icon(Icons.add, size: 20),
                            tooltip: 'New group',
                            onPressed: () =>
                                _createGroupInline(context, provider),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),

            // Gender
            Text('Gender',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('Female')),
                ButtonSegment(value: 'male', label: Text('Male')),
                ButtonSegment(value: 'unknown', label: Text('Unknown')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) =>
                  setState(() => _gender = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Purpose
            Text('Purpose',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'layer', label: Text('Layer')),
                ButtonSegment(value: 'meat', label: Text('Meat')),
                ButtonSegment(value: 'dual', label: Text('Dual Purpose')),
              ],
              selected: {_purpose},
              onSelectionChanged: (s) =>
                  setState(() => _purpose = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 4),

            // How acquired
            Text('How did she join the flock?',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'hatched', label: Text('Hatched')),
                ButtonSegment(value: 'bought', label: Text('Bought')),
              ],
              selected: {_acquiredVia},
              onSelectionChanged: (s) =>
                  setState(() => _acquiredVia = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),

            if (_acquiredVia == 'hatched') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hatch Date'),
                subtitle: Text(_hatchDate != null
                    ? DateFormat('d MMMM yyyy').format(_hatchDate!)
                    : 'Not set'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _hatchDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setState(() => _hatchDate = picked);
                },
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date Bought'),
                subtitle: Text(_buyDate != null
                    ? DateFormat('d MMMM yyyy').format(_buyDate!)
                    : 'Not set'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _buyDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setState(() => _buyDate = picked);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageAtPurchaseController,
                decoration: const InputDecoration(
                  labelText: 'Age when bought (weeks)',
                  hintText: 'e.g. 19',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (_acquiredVia != 'bought') return null;
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      int.tryParse(v.trim()) == null) {
                    return 'Please enter a whole number';
                  }
                  return null;
                },
              ),
            ],
            const Divider(),
            const SizedBox(height: 12),

            // Colour/markings
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Colour & markings',
                hintText: 'e.g. White with black tips',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Egg colour picker
            Text('Egg Colour',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Helps auto-identify which hen laid each egg',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kEggColorCategories.map((cat) {
                final selected = _eggColorCategory == cat;
                final swatch = eggColorSwatch(cat);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _eggColorCategory = selected ? null : cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            selected ? Colors.black : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.check,
                                size: 14,
                                color: eggColorTextColor(cat)),
                          ),
                        Text(
                          kEggColorLabels[cat] ?? cat,
                          style: TextStyle(
                              fontSize: 12,
                              color: eggColorTextColor(cat),
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Sample egg photos
            Text('Sample Egg Photos (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Up to 3 photos for visual reference',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                ..._samplePhotos.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(p),
                                width: 72, height: 72, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _samplePhotos.remove(p)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (_samplePhotos.length < 3)
                  GestureDetector(
                    onTap: _pickSampleEggPhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Status (only when editing)
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'deceased', child: Text('Deceased')),
                  DropdownMenuItem(
                      value: 'missing', child: Text('Missing')),
                  DropdownMenuItem(
                      value: 'slaughtered', child: Text('Slaughtered')),
                ],
                onChanged: (v) =>
                    setState(() => _status = v ?? 'active'),
              ),
              if (_status != 'active') ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(_statusDate != null
                      ? DateFormat('d MMMM yyyy').format(_statusDate!)
                      : 'Not set'),
                  trailing:
                      const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _statusDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null)
                      setState(() => _statusDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _statusNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Cause / note',
                    hintText: 'e.g. Fox attack, Old age',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                // Slaughter weights — shown only when status is slaughtered
                if (_status == 'slaughtered') ...[
                  const SizedBox(height: 16),
                  Text('Slaughter Weights (grams)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _liveWeightController,
                          decoration: const InputDecoration(
                            labelText: 'Live weight (g)',
                            hintText: 'e.g. 2800',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dressedWeightController,
                          decoration: const InputDecoration(
                            labelText: 'Dressed weight (g)',
                            hintText: 'e.g. 2050',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dressed = plucked & eviscerated (oven-ready). '
                    'App will calculate dressing %.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
              const SizedBox(height: 20),
            ],

            // Save button
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Add to Flock'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
