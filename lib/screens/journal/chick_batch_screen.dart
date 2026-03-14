import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/journal_provider.dart';
import '../../models/chick_batch.dart';

class ChickBatchScreen extends StatefulWidget {
  final String? batchId; // null → creating new

  const ChickBatchScreen({super.key, this.batchId});

  @override
  State<ChickBatchScreen> createState() => _ChickBatchScreenState();
}

class _ChickBatchScreenState extends State<ChickBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _eggCountController = TextEditingController();
  final _eggsHatchedController = TextEditingController();
  final _incubatorController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  String _status = 'incubating';
  bool _saving = false;

  ChickBatch? _existingBatch;
  bool get _isEditing => widget.batchId != null && _existingBatch != null;

  @override
  void initState() {
    super.initState();
    if (widget.batchId != null) {
      final batch =
          context.read<JournalProvider>().getBatchById(widget.batchId!);
      if (batch != null) {
        _existingBatch = batch;
        _nameController.text = batch.name;
        _breedController.text = batch.breed ?? '';
        _eggCountController.text = batch.eggCount.toString();
        _eggsHatchedController.text =
            batch.eggsHatched?.toString() ?? '';
        _incubatorController.text = batch.incubatorType ?? '';
        _notesController.text = batch.notes ?? '';
        _startDate = batch.startDate;
        _status = batch.status;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _eggCountController.dispose();
    _eggsHatchedController.dispose();
    _incubatorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<JournalProvider>();
    final eggCount = int.tryParse(_eggCountController.text.trim()) ?? 0;
    final eggsHatched =
        int.tryParse(_eggsHatchedController.text.trim());

    if (_isEditing) {
      final updated = _existingBatch!.copyWith(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        startDate: _startDate,
        eggCount: eggCount,
        eggsHatched: eggsHatched,
        incubatorType: _incubatorController.text.trim().isNotEmpty
            ? _incubatorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: _status,
      );
      await provider.updateBatch(updated);
    } else {
      await provider.addBatch(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        startDate: _startDate,
        eggCount: eggCount,
        incubatorType: _incubatorController.text.trim().isNotEmpty
            ? _incubatorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this clutch?'),
        content: const Text(
            'This removes the clutch and unlinks associated entries. The entries themselves are kept.'),
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
      await context
          .read<JournalProvider>()
          .deleteBatch(widget.batchId!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute derived fields for display
    final expectedHatch = _startDate.add(const Duration(days: 21));
    final daysIn =
        DateTime.now().difference(_startDate).inDays.clamp(0, 21);
    final progress = daysIn / 21.0;

    ChickBatch? batch = _existingBatch;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Clutch' : 'New Clutch'),
        actions: [
          if (_isEditing)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progress bar (only for incubating/hatching)
            if (_isEditing &&
                (_status == 'incubating' || _status == 'hatching')) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Day $daysIn of 21',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            daysIn < 21
                                ? 'Expected ${DateFormat('d MMM').format(expectedHatch)}'
                                : 'Hatch day!',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Milestone dots — proportionally placed at D7/21, D18/21, D21/21
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const milestones = [
                            (day: 7, label: 'Candling'),
                            (day: 18, label: 'Lockdown'),
                            (day: 21, label: 'Hatch!'),
                          ];
                          return SizedBox(
                            height: 38,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: milestones.map((m) {
                                // Center each dot at its proportional position
                                final centerX =
                                    (m.day / 21.0) * constraints.maxWidth;
                                return Positioned(
                                  left: centerX - 24,
                                  top: 0,
                                  child: SizedBox(
                                    width: 48,
                                    child: _milestone(
                                        m.label, m.day, daysIn, context),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hatch rate (if available)
            if (_isEditing && batch?.hatchRate != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.egg_outlined),
                      const SizedBox(width: 12),
                      Text(
                        '${batch!.eggsHatched}/${batch.eggCount} hatched — '
                        '${batch.hatchRate!.toStringAsFixed(0)}% hatch rate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Clutch name *',
                hintText: 'e.g. Spring Silkies 2025',
              ),
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
                hintText: 'e.g. Silkie, mixed heritage, RIR × Australorp',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Incubation start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incubation Start Date'),
              subtitle: Text(DateFormat('d MMMM yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expected Hatch Date'),
              subtitle: Text(
                  DateFormat('d MMMM yyyy').format(expectedHatch)),
              leading:
                  const Icon(Icons.event, color: Color(0xFF5D8A3C)),
            ),
            const SizedBox(height: 12),

            // Egg count
            TextFormField(
              controller: _eggCountController,
              decoration:
                  const InputDecoration(labelText: 'Eggs set *'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter the number of eggs set';
                }
                if (int.tryParse(v.trim()) == null) {
                  return 'Please enter a whole number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Eggs hatched (optional)
            TextFormField(
              controller: _eggsHatchedController,
              decoration: const InputDecoration(
                labelText: 'Eggs hatched',
                hintText: 'Fill in on hatch day',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (int.tryParse(v.trim()) == null) {
                  return 'Please enter a whole number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Incubator
            TextFormField(
              controller: _incubatorController,
              decoration: const InputDecoration(
                labelText: 'Incubator',
                hintText: 'e.g. Brinsea Eco 20, Still air box',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Temperature, humidity, turning method...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                    value: 'incubating', child: Text('Incubating')),
                DropdownMenuItem(
                    value: 'hatching', child: Text('Hatching')),
                DropdownMenuItem(
                    value: 'raising', child: Text('Raising Chicks')),
                DropdownMenuItem(
                    value: 'growing', child: Text('Growing Up')),
                DropdownMenuItem(
                    value: 'completed', child: Text('Completed')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
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
                  : Text(_isEditing ? 'Save Changes' : 'Start Clutch'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _milestone(
      String label, int day, int currentDay, BuildContext context) {
    final reached = currentDay >= day;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: reached
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          child: Text(
            'D$day',
            style: TextStyle(
              fontSize: 8,
              color: reached ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: reached
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
