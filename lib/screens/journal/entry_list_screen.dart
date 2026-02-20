import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/journal_provider.dart';
import '../../models/journal_entry.dart';
import 'entry_edit_screen.dart';

class EntryListScreen extends StatelessWidget {
  final String trackType;
  const EntryListScreen({super.key, required this.trackType});

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final entries = provider.entriesByTrack(trackType);

        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    _emptyMessage(trackType),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Record a note'),
                    onPressed: () => _openAdd(context),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _EntryCard(
                  entry: entry,
                  onTap: () => _openEdit(context, entry),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'fab_$trackType',
                onPressed: () => _openAdd(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EntryEditScreen(initialTrackType: trackType)),
    );
  }

  void _openEdit(BuildContext context, JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryEditScreen(entry: entry)),
    );
  }

  String _emptyMessage(String track) {
    switch (track) {
      case 'general':
        return 'No general notes yet.\nRecord your observations, learnings, and brooder updates!';
      case 'flock':
        return 'No flock notes yet.\nNote behavioural changes, first eggs, moults, and more.';
      case 'chick':
        return 'No chick notes yet.\nTrack incubation, hatch day, and brooding milestones.';
      default:
        return 'No entries yet — add your first one!';
    }
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const _EntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('d MMM').format(entry.date),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (entry.isRetroactive)
                        Text(
                          'past date',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary,
                              fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: entry.tags
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .map((t) => Chip(
                            label: Text(t),
                            labelStyle:
                                const TextStyle(fontSize: 11),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              if (entry.chickStage != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.chickStage!.replaceAll('_', ' '),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
