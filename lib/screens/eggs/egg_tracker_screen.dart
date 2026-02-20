import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../providers/egg_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../models/egg_record.dart';
import '../../models/chicken.dart';
import '../../utils/egg_color_matcher.dart';
import '../../utils/export_utils.dart';
import '../../providers/journal_provider.dart';
import 'egg_capture_screen.dart';
import 'egg_stats_screen.dart';

class EggTrackerScreen extends StatelessWidget {
  const EggTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eggs'),
        actions: [
          IconButton(
            tooltip: 'View charts',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EggStatsScreen())),
          ),
          Consumer2<EggProvider, ChickenProvider>(
            builder: (context, eggProvider, chickenProvider, _) =>
                IconButton(
              tooltip: 'Export to Excel',
              icon: const Icon(Icons.download_outlined),
              onPressed: eggProvider.records.isEmpty
                  ? null
                  : () async {
                      try {
                        await exportToExcel(
                          eggRecords: eggProvider.records,
                          chickens: chickenProvider.chickens,
                          batches: context
                              .read<JournalProvider>()
                              .batches,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Export failed: $e')),
                          );
                        }
                      }
                    },
            ),
          ),
        ],
      ),
      body: Consumer2<EggProvider, ChickenProvider>(
        builder: (context, eggProvider, chickenProvider, _) {
          final records = eggProvider.records;

          if (eggProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.egg_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No eggs recorded yet — add your first one!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add egg records'),
                    onPressed: () => _openCapture(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final chicken = record.chickenId != null
                  ? chickenProvider.getById(record.chickenId!)
                  : null;
              return _EggRecordCard(
                record: record,
                chicken: chicken,
                onTap: () => _openEdit(context, record),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCapture(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add eggs'),
      ),
    );
  }

  void _openCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EggCaptureScreen()),
    );
  }

  void _openEdit(BuildContext context, EggRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EggCaptureScreen(existingRecord: record)),
    );
  }
}

class _EggRecordCard extends StatelessWidget {
  final EggRecord record;
  final Chicken? chicken;
  final VoidCallback onTap;

  const _EggRecordCard({
    required this.record,
    required this.chicken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chickenName =
        chicken?.name ?? record.breedNote ?? 'Unassigned';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Egg photo or colour dot
              if (record.photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(record.photoPath!),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: eggColorSwatch(record.eggColorCategory)
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: eggColorSwatch(record.eggColorCategory),
                        border: Border.all(
                            color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chickenName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMMM yyyy').format(record.date),
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.weightGrams.toStringAsFixed(1)}g',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(record.sizeGrade,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  // Egg colour swatch
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            eggColorSwatch(record.eggColorCategory),
                        border: Border.all(
                            color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
