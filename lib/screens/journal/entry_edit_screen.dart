import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../providers/journal_provider.dart';
import '../../models/journal_entry.dart';

class EntryEditScreen extends StatefulWidget {
  final JournalEntry? entry; // null → new entry
  final String? initialTrackType;

  const EntryEditScreen({super.key, this.entry, this.initialTrackType});

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  late String _trackType;
  late DateTime _date;
  List<String> _photoPaths = [];
  String? _chickBatchId;
  String? _chickStage;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.entry!;
      _trackType = e.trackType;
      _date = e.date;
      _titleController.text = e.title;
      _contentController.text = e.content;
      _tagsController.text = e.tags;
      _photoPaths = List.from(e.photoPaths);
      _chickBatchId = e.chickBatchId;
      _chickStage = e.chickStage;
    } else {
      _trackType = widget.initialTrackType ?? 'general';
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    for (final img in picked) {
      final compressed = await _compressImage(img.path);
      if (compressed != null && mounted) {
        setState(() => _photoPaths.add(compressed));
      }
    }
  }

  Future<String?> _compressImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath = '${dir.path}/journal_${const Uuid().v4()}.jpg';
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

    final provider = context.read<JournalProvider>();

    if (_isEditing) {
      await provider.updateEntry(widget.entry!.copyWith(
        trackType: _trackType,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _date,
        tags: _tagsController.text.trim(),
        photoPaths: _photoPaths,
        chickBatchId: _chickBatchId,
        chickStage: _chickStage,
      ));
    } else {
      await provider.addEntry(
        trackType: _trackType,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _date,
        tags: _tagsController.text.trim(),
        photoPaths: _photoPaths,
        chickBatchId: _chickBatchId,
        chickStage: _chickStage,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This cannot be undone.'),
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
      await context.read<JournalProvider>().deleteEntry(widget.entry!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JournalProvider>();
    final batches = provider.batches;

    // Determine if date is today vs past
    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Record a Note'),
        actions: [
          if (_isEditing)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Track type (only when adding new)
            if (!_isEditing)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'general', label: Text('General')),
                  ButtonSegment(value: 'flock', label: Text('Flock')),
                  ButtonSegment(value: 'chick', label: Text('Chick')),
                ],
                selected: {_trackType},
                onSelectionChanged: (s) =>
                    setState(() => _trackType = s.first),
              ),
            if (!_isEditing) const SizedBox(height: 16),

            // Date picker — prominent
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  isToday
                      ? 'Today, ${DateFormat('d MMMM yyyy').format(_date)}'
                      : DateFormat('d MMMM yyyy').format(_date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: !isToday
                    ? Text(
                        'Recorded for a past date',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            fontSize: 12),
                      )
                    : null,
                trailing: const Text('Change',
                    style:
                        TextStyle(color: Color(0xFF5D8A3C), fontSize: 13)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please add a title' : null,
            ),
            const SizedBox(height: 12),

            // Body
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Write your observations...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'behaviour, moult, first egg  (comma-separated)',
              ),
            ),
            const SizedBox(height: 16),

            // Chick-specific fields
            if (_trackType == 'chick') ...[
              // Batch picker
              DropdownButtonFormField<String?>(
                value: _chickBatchId,
                decoration: const InputDecoration(labelText: 'Clutch'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No clutch')),
                  ...batches.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      )),
                ],
                onChanged: (v) => setState(() => _chickBatchId = v),
              ),
              const SizedBox(height: 12),

              // Life stage
              DropdownButtonFormField<String?>(
                value: _chickStage,
                decoration: const InputDecoration(labelText: 'Life Stage'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Not set')),
                  DropdownMenuItem(
                      value: 'incubating', child: Text('Incubating')),
                  DropdownMenuItem(
                      value: 'hatching', child: Text('Hatching Day')),
                  DropdownMenuItem(
                      value: 'brooding', child: Text('Raising Chicks')),
                  DropdownMenuItem(
                      value: 'weaning', child: Text('Growing Up')),
                  DropdownMenuItem(
                      value: 'graduated',
                      child: Text('Living Outside')),
                ],
                onChanged: (v) => setState(() => _chickStage = v),
              ),
              const SizedBox(height: 16),
            ],

            // Photos
            Text('Photos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_photoPaths.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoPaths.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _photoPaths.length) {
                      return _AddPhotoButton(onTap: _pickPhotos);
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_photoPaths[index]),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _photoPaths.removeAt(index)),
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
                    );
                  },
                ),
              )
            else
              _AddPhotoButton(onTap: _pickPhotos),
            const SizedBox(height: 24),

            // Save
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Save Note'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey, size: 28),
            const SizedBox(height: 2),
            Text('Add photo',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
