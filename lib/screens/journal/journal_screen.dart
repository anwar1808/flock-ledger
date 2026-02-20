import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/journal_provider.dart';
import 'entry_list_screen.dart';
import 'chick_batch_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  int _selectedTrack = 0;

  static const _tracks = [
    _Track(key: 'general', label: 'General'),
    _Track(key: 'flock', label: 'Flock'),
    _Track(key: 'chick', label: 'Chick'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: _tracks.asMap().entries.map((e) {
                final selected = e.key == _selectedTrack;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.value.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedTrack = e.key),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _selectedTrack == 2
          ? const _ChickTabBody()
          : EntryListScreen(trackType: _tracks[_selectedTrack].key),
    );
  }
}

class _Track {
  final String key;
  final String label;
  const _Track({required this.key, required this.label});
}

/// The Chick tab shows batches + an entry list below.
class _ChickTabBody extends StatelessWidget {
  const _ChickTabBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final batches = provider.batches;

        return Column(
          children: [
            // Clutch / Batch header strip
            if (batches.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: batches.length + 1, // +1 for "Add Clutch" button
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == batches.length) {
                      return _AddClutchChip(onTap: () => _openAddBatch(context));
                    }
                    final batch = batches[index];
                    return _ClutchChip(
                      name: batch.name,
                      status: batch.status,
                      progress: batch.incubationProgress,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChickBatchScreen(batchId: batch.id),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Start a new clutch'),
                  onPressed: () => _openAddBatch(context),
                ),
              ),
            const Divider(height: 1),
            // Entry list for chick track
            Expanded(child: EntryListScreen(trackType: 'chick')),
          ],
        );
      },
    );
  }

  void _openAddBatch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChickBatchScreen()),
    );
  }
}

class _ClutchChip extends StatelessWidget {
  final String name;
  final String status;
  final double progress;
  final VoidCallback onTap;

  const _ClutchChip({
    required this.name,
    required this.status,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(status.replaceAll('_', ' '),
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 11)),
            const Spacer(),
            if (status == 'incubating' || status == 'hatching') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddClutchChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddClutchChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text('New\nClutch',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
