import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/journal_provider.dart';
import '../../models/chick_batch.dart';
import '../../screens/settings/settings_screen.dart';
import '../../utils/breed_incubation_table.dart';
import 'chick_sexing_screen.dart';

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
  final _breedFocusNode = FocusNode();

  DateTime _startDate = DateTime.now();
  String _status = 'incubating';
  bool _saving = false;

  // Incubation settings
  int _incubationDays = 21;
  int _hatchWindowDays = 3;
  bool _breedLookupLoading = false;
  String? _breedLookupNote; // e.g. "21 days · Chicken"

  ChickBatch? _existingBatch;
  bool get _isEditing => widget.batchId != null && _existingBatch != null;

  @override
  void initState() {
    super.initState();

    // Trigger breed lookup when focus leaves the breed field
    _breedFocusNode.addListener(() {
      if (!_breedFocusNode.hasFocus) {
        final breed = _breedController.text.trim();
        if (breed.isNotEmpty) _lookupBreed(breed);
      }
    });

    if (widget.batchId != null) {
      final batch =
          context.read<JournalProvider>().getBatchById(widget.batchId!);
      if (batch != null) {
        _existingBatch = batch;
        _nameController.text = batch.name;
        _breedController.text = batch.breed ?? '';
        _eggCountController.text = batch.eggCount.toString();
        _eggsHatchedController.text = batch.eggsHatched?.toString() ?? '';
        _incubatorController.text = batch.incubatorType ?? '';
        _notesController.text = batch.notes ?? '';
        _startDate = batch.startDate;
        _status = batch.status;
        _incubationDays = batch.incubationDays;
        _hatchWindowDays = batch.hatchWindowDays;
        if (batch.breed != null) {
          _breedLookupNote = '$_incubationDays days · saved';
        }
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
    _breedFocusNode.dispose();
    super.dispose();
  }

  Future<void> _lookupBreed(String breed) async {
    setState(() {
      _breedLookupLoading = true;
      _breedLookupNote = null;
    });
    final userKey = await SettingsScreen.getApiKey();
    final info = await lookupBreedIncubation(breed, userApiKey: userKey);
    if (mounted) {
      setState(() {
        _incubationDays = info.days;
        _breedLookupNote = info.note != null
            ? '${info.days} days · ${info.species} · ${info.note}'
            : '${info.days} days · ${info.species}';
        _breedLookupLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<JournalProvider>();
    final eggCount = int.tryParse(_eggCountController.text.trim()) ?? 0;
    final eggsHatched = int.tryParse(_eggsHatchedController.text.trim());

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
        incubationDays: _incubationDays,
        hatchWindowDays: _hatchWindowDays,
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
        incubationDays: _incubationDays,
        hatchWindowDays: _hatchWindowDays,
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
      await context.read<JournalProvider>().deleteBatch(widget.batchId!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _incubationDays + _hatchWindowDays;
    final daysIn =
        DateTime.now().difference(_startDate).inDays.clamp(0, totalDays);
    final expectedHatch = _startDate.add(Duration(days: _incubationDays));
    final lastHatch = _startDate.add(Duration(days: totalDays));

    final ChickBatch? batch = _existingBatch;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Clutch' : 'New Clutch'),
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
            // ── Progress bar (incubating / hatching only) ──────────────────
            if (_isEditing &&
                (_status == 'incubating' || _status == 'hatching')) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _progressHeader(
                          daysIn, expectedHatch, lastHatch, context),
                      const SizedBox(height: 12),
                      _progressBar(daysIn, context),
                      const SizedBox(height: 10),
                      _milestones(daysIn, totalDays, context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Hatch rate ────────────────────────────────────────────────
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
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Sex my chicks button ──────────────────────────────────────
            if (_isEditing &&
                (_status == 'raising' || _status == 'growing')) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Sex my chicks with Claude'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChickSexingScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Clutch name ───────────────────────────────────────────────
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

            // ── Breed + lookup ────────────────────────────────────────────
            TextFormField(
              controller: _breedController,
              focusNode: _breedFocusNode,
              decoration: const InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g. Silkie, Orpington, Pekin Duck',
                helperText: 'Incubation days set automatically when you leave this field',
              ),
              textCapitalization: TextCapitalization.words,
              onEditingComplete: () {
                _breedFocusNode.unfocus();
              },
            ),
            // Breed lookup feedback
            if (_breedLookupLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Looking up incubation period…',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              )
            else if (_breedLookupNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF5D8A3C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _breedLookupNote!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF5D8A3C)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Incubation period stepper ─────────────────────────────────
            _StepperRow(
              label: 'Incubation period',
              value: '$_incubationDays days',
              hint: 'Auto-set by breed · adjust if your hatch runs long',
              onDecrement: _incubationDays > 14
                  ? () => setState(() {
                        _incubationDays--;
                        _breedLookupNote = null;
                      })
                  : null,
              onIncrement: _incubationDays < 42
                  ? () => setState(() {
                        _incubationDays++;
                        _breedLookupNote = null;
                      })
                  : null,
            ),
            const SizedBox(height: 8),

            // ── Hatch window stepper ──────────────────────────────────────
            _StepperRow(
              label: 'Hatch window',
              value: _hatchWindowDays == 0
                  ? 'none'
                  : '$_hatchWindowDays ${_hatchWindowDays == 1 ? 'day' : 'days'}',
              hint: 'Extra days to wait past expected hatch before giving up',
              onDecrement: _hatchWindowDays > 0
                  ? () => setState(() => _hatchWindowDays--)
                  : null,
              onIncrement: _hatchWindowDays < 7
                  ? () => setState(() => _hatchWindowDays++)
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Dates ─────────────────────────────────────────────────────
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
              subtitle: Text(DateFormat('d MMMM yyyy').format(expectedHatch)),
              leading: const Icon(Icons.event, color: Color(0xFF5D8A3C)),
            ),
            if (_hatchWindowDays > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Latest Hatch Date'),
                subtitle: Text(DateFormat('d MMMM yyyy').format(lastHatch)),
                leading: Icon(Icons.event_outlined,
                    color: Colors.orange.shade600),
              ),
            const SizedBox(height: 12),

            // ── Egg count ─────────────────────────────────────────────────
            TextFormField(
              controller: _eggCountController,
              decoration: const InputDecoration(labelText: 'Eggs set *'),
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

            // ── Eggs hatched ──────────────────────────────────────────────
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

            // ── Incubator ─────────────────────────────────────────────────
            TextFormField(
              controller: _incubatorController,
              decoration: const InputDecoration(
                labelText: 'Incubator',
                hintText: 'e.g. Brinsea Eco 20, Still air box',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // ── Notes ─────────────────────────────────────────────────────
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

            // ── Status ────────────────────────────────────────────────────
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

  // ── Progress header ────────────────────────────────────────────────────────

  Widget _progressHeader(int daysIn, DateTime expectedHatch,
      DateTime lastHatch, BuildContext context) {
    final inWindow =
        daysIn > _incubationDays && daysIn <= _incubationDays + _hatchWindowDays;
    final isHatchDay = daysIn == _incubationDays;
    final overdue = daysIn > _incubationDays + _hatchWindowDays;

    String rightText;
    Color rightColor;

    if (overdue) {
      rightText = 'Past hatch window';
      rightColor = Colors.red.shade400;
    } else if (isHatchDay) {
      rightText = 'Hatch day!';
      rightColor = Theme.of(context).colorScheme.primary;
    } else if (inWindow) {
      final extra = daysIn - _incubationDays;
      rightText =
          '+${extra}d — latest ${DateFormat('d MMM').format(lastHatch)}';
      rightColor = Colors.orange.shade700;
    } else {
      rightText = 'Expected ${DateFormat('d MMM').format(expectedHatch)}';
      rightColor = Colors.grey.shade600;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Day $daysIn',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          rightText,
          style: TextStyle(color: rightColor, fontSize: 13),
        ),
      ],
    );
  }

  // ── Two-tone progress bar ──────────────────────────────────────────────────

  Widget _progressBar(int daysIn, BuildContext context) {
    final greenFill =
        (daysIn / _incubationDays).clamp(0.0, 1.0);
    final amberFill = _hatchWindowDays > 0
        ? ((daysIn - _incubationDays).clamp(0, _hatchWindowDays) /
                _hatchWindowDays)
            .clamp(0.0, 1.0)
        : 0.0;
    final splitFraction =
        _incubationDays / (_incubationDays + _hatchWindowDays);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final greenZoneWidth = splitFraction * totalWidth;
        final amberZoneWidth = (1 - splitFraction) * totalWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                // Green zone — core incubation period
                SizedBox(
                  width: greenZoneWidth,
                  child: Stack(children: [
                    Container(color: Colors.grey.shade200),
                    FractionallySizedBox(
                      widthFactor: greenFill,
                      child: Container(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ]),
                ),
                // Divider
                if (_hatchWindowDays > 0)
                  Container(width: 1.5, color: Colors.white),
                // Amber zone — hatch window
                if (_hatchWindowDays > 0)
                  SizedBox(
                    width: amberZoneWidth - 1.5,
                    child: Stack(children: [
                      Container(color: Colors.grey.shade100),
                      FractionallySizedBox(
                        widthFactor: amberFill,
                        child: Container(color: Colors.orange.shade300),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Milestone markers ──────────────────────────────────────────────────────

  Widget _milestones(int daysIn, int totalDays, BuildContext context) {
    // Build milestone list based on incubation period
    final milestones = <(int, String)>[];
    if (_incubationDays > 7) milestones.add((7, 'Candling'));
    if (_incubationDays > 10) {
      milestones.add((_incubationDays - 3, 'Lockdown'));
    }
    milestones.add((_incubationDays, 'Hatch!'));

    return LayoutBuilder(
      builder: (ctx, constraints) {
        return SizedBox(
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: milestones.map((m) {
              final (day, label) = m;
              final centerX = (day / totalDays) * constraints.maxWidth;
              return Positioned(
                left: (centerX - 24).clamp(0.0, constraints.maxWidth - 48),
                top: 0,
                child: SizedBox(
                  width: 48,
                  child: _milestone(label, day, daysIn, context),
                ),
              );
            }).toList(),
          ),
        );
      },
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

// ── Reusable stepper row ───────────────────────────────────────────────────────

class _StepperRow extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.hint,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: onDecrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: onIncrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        Text(hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
