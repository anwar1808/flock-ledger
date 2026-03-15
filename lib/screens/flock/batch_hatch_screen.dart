import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/chicken_provider.dart';
import '../../models/flock_group.dart';

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
                const DropdownMenuItem(value: null, child: Text('Ungrouped')),
                ...groups.map((g) =>
                    DropdownMenuItem(value: g.id, child: Text(g.name))),
              ],
              onChanged: (v) => setState(() => _flockGroupId = v),
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
