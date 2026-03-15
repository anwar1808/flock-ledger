import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/chicken_provider.dart';
import '../../models/flock_group.dart';

const _kCreate = '__create__';

class BatchHatchScreen extends StatefulWidget {
  const BatchHatchScreen({super.key});

  @override
  State<BatchHatchScreen> createState() => _BatchHatchScreenState();
}

class _BatchHatchScreenState extends State<BatchHatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prefixController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _breedController = TextEditingController();

  DateTime _hatchDate = DateTime.now();
  String? _flockGroupId;
  bool _saving = false;

  @override
  void dispose() {
    _prefixController.dispose();
    _countController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  int get _count => int.tryParse(_countController.text.trim()) ?? 0;

  List<String> get _previewNames {
    final prefix = _prefixController.text.trim();
    if (prefix.isEmpty || _count <= 0) return [];
    return List.generate(_count, (i) => '$prefix ${i + 1}');
  }

  Future<void> _createNewFlock() async {
    final nameController = TextEditingController();
    String selectedColor = kFlockGroupColors.first;

    final created = await showDialog<FlockGroup>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create new flock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Flock name',
                  hintText: 'e.g. Main Flock',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Colour', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kFlockGroupColors.map((hex) {
                  final color = Color(
                      int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final chosen = hex == selectedColor;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: chosen ? Colors.black87 : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: chosen
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final group =
                    await context.read<ChickenProvider>().addFlockGroup(
                          name: name,
                          colorHex: selectedColor,
                        );
                if (ctx.mounted) Navigator.pop(ctx, group);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created != null && mounted) {
      setState(() => _flockGroupId = created.id);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await context.read<ChickenProvider>().addHatchBatch(
          prefix: _prefixController.text.trim(),
          count: _count,
          hatchDate: _hatchDate,
          breed: _breedController.text.trim().isNotEmpty
              ? _breedController.text.trim()
              : null,
          flockGroupId: _flockGroupId,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<ChickenProvider>().flockGroups;

    return Scaffold(
      appBar: AppBar(title: const Text('Add from Hatch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
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
                'Creates multiple birds from the same hatch, named with '
                'a shared prefix and numbered automatically. '
                'You can rename them individually afterwards.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Name prefix
            TextFormField(
              controller: _prefixController,
              decoration: const InputDecoration(
                labelText: 'Name prefix *',
                hintText: 'e.g. Spring Silkie',
                helperText: 'Birds will be named: Spring Silkie 1, Spring Silkie 2…',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name prefix' : null,
            ),
            const SizedBox(height: 16),

            // Count
            TextFormField(
              controller: _countController,
              decoration: const InputDecoration(
                labelText: 'Number of chicks *',
                hintText: 'e.g. 6',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'Enter at least 1';
                if (n > 50) return 'Maximum 50 at a time';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hatch date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hatch date'),
              subtitle: Text(DateFormat('d MMMM yyyy').format(_hatchDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _hatchDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _hatchDate = picked);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Breed
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed (optional)',
                hintText: 'e.g. Silkie, Rhode Island Red',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Flock group
            DropdownButtonFormField<String?>(
              value: _flockGroupId,
              decoration:
                  const InputDecoration(labelText: 'Flock group (optional)'),
              items: [
                DropdownMenuItem(
                  value: _kCreate,
                  child: Row(children: [
                    const Icon(Icons.add, size: 16),
                    const SizedBox(width: 6),
                    Text('+ Create new flock',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
                const DropdownMenuItem(value: null, child: Text('Ungrouped')),
                ...groups.map((g) =>
                    DropdownMenuItem(value: g.id, child: Text(g.name))),
              ],
              onChanged: (v) {
                if (v == _kCreate) {
                  _createNewFlock();
                } else {
                  setState(() => _flockGroupId = v);
                }
              },
            ),
            const SizedBox(height: 24),

            // Live preview
            if (_previewNames.isNotEmpty) ...[
              Text('Preview',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _previewNames.take(8).join(', ') +
                      (_previewNames.length > 8
                          ? '  …+${_previewNames.length - 8} more'
                          : ''),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Add ${_count > 0 ? _count : ''} '
                      '${_count == 1 ? 'bird' : 'birds'}'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
