import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/loss_event.dart';
import '../../providers/chicken_provider.dart';

class LossEventScreen extends StatefulWidget {
  const LossEventScreen({super.key});

  @override
  State<LossEventScreen> createState() => _LossEventScreenState();
}

class _LossEventScreenState extends State<LossEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _statusApplied = 'slaughtered';
  DateTime _date = DateTime.now();
  final Set<String> _selectedIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one bird')),
      );
      return;
    }
    setState(() => _saving = true);

    await context.read<ChickenProvider>().logLossEvent(
          title: _titleController.text.trim(),
          statusApplied: _statusApplied,
          date: _date,
          affectedChickenIds: _selectedIds.toList(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChickenProvider>();
    final activeBirds = provider.activeChickens;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Loss Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // What happened
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What happened? *',
                hintText: 'e.g. Fox attack, Illness, Predator',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please describe what happened'
                  : null,
            ),
            const SizedBox(height: 16),

            // Status applied
            DropdownButtonFormField<String>(
              value: _statusApplied,
              decoration: const InputDecoration(labelText: 'Outcome'),
              items: kLossStatuses.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(kLossStatusLabels[s]!),
                );
              }).toList(),
              onChanged: (v) =>
                  setState(() => _statusApplied = v ?? 'slaughtered'),
            ),
            const SizedBox(height: 8),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('d MMMM yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
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
            const Divider(),
            const SizedBox(height: 8),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional details...',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Bird selector
            Text('Which birds were affected? *',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Tap to select — they will be moved to your archive',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 10),

            if (activeBirds.isEmpty)
              Text('No active birds in your flock.',
                  style: TextStyle(color: Colors.grey.shade500))
            else
              ...activeBirds.map((bird) {
                final selected = _selectedIds.contains(bird.id);
                return CheckboxListTile(
                  value: selected,
                  title: Text(bird.name),
                  subtitle: Text(
                    [
                      bird.displayTerm,
                      if (bird.breed != null) bird.breed!,
                    ].join(' · '),
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedIds.add(bird.id);
                    } else {
                      _selectedIds.remove(bird.id);
                    }
                  }),
                );
              }),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.error),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Log Event (${_selectedIds.length} bird${_selectedIds.length == 1 ? '' : 's'})'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
