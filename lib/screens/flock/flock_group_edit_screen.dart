import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/flock_group.dart';
import '../../providers/chicken_provider.dart';

class FlockGroupEditScreen extends StatefulWidget {
  final FlockGroup? group; // null → creating new

  const FlockGroupEditScreen({super.key, this.group});

  @override
  State<FlockGroupEditScreen> createState() => _FlockGroupEditScreenState();
}

class _FlockGroupEditScreenState extends State<FlockGroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _colorHex = kFlockGroupColors.first;
  bool _saving = false;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.group!.name;
      _notesController.text = widget.group!.notes ?? '';
      _colorHex = widget.group!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ChickenProvider>();
    final notes = _notesController.text.trim();

    if (_isEditing) {
      await provider.updateFlockGroup(widget.group!.copyWith(
        name: _nameController.text.trim(),
        colorHex: _colorHex,
        notes: notes.isNotEmpty ? notes : null,
      ));
    } else {
      await provider.addFlockGroup(
        name: _nameController.text.trim(),
        colorHex: _colorHex,
        notes: notes.isNotEmpty ? notes : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final provider = context.read<ChickenProvider>();
    final memberCount =
        provider.chickensInGroup(widget.group!.id).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this group?'),
        content: Text(memberCount > 0
            ? 'The $memberCount ${memberCount == 1 ? 'hen' : 'hens'} in this group will become ungrouped. Their profiles are kept.'
            : 'This group will be removed.'),
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
      await context.read<ChickenProvider>().deleteFlockGroup(widget.group!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group' : 'New Flock Group'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name *',
                hintText: 'e.g. Main Flock, Bantam Run, Quarantine',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 20),

            Text('Colour', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kFlockGroupColors.map((hex) {
                final selected = _colorHex == hex;
                final color = _hexColor(hex);
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g. Back garden run, heritage breeds',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Create Group'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
