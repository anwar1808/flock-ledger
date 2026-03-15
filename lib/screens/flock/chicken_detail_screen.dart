import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../providers/chicken_provider.dart';
import '../../providers/egg_provider.dart';
import '../../models/chicken.dart';
import '../../models/egg_record.dart';
import '../../utils/egg_color_matcher.dart';
import 'chicken_edit_screen.dart';
import '../journal/chick_sexing_screen.dart';

class ChickenDetailScreen extends StatelessWidget {
  final String chickenId;
  const ChickenDetailScreen({super.key, required this.chickenId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChickenProvider, EggProvider>(
      builder: (context, chickenProvider, eggProvider, _) {
        final chicken = chickenProvider.getById(chickenId);
        if (chicken == null) {
          return const Scaffold(
            body: Center(child: Text('Chicken not found')),
          );
        }
        final records = eggProvider.recordsForChicken(chickenId);
        records.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: Text(chicken.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChickenEditScreen(chicken: chicken)),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChickenHeader(chicken: chicken),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Sex this bird with Claude'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChickSexingScreen(chickenId: chicken.id),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _EggStatsCard(records: records, chicken: chicken),
              const SizedBox(height: 16),
              _EggHistoryList(records: records),
            ],
          ),
        );
      },
    );
  }
}

class _ChickenHeader extends StatelessWidget {
  final Chicken chicken;
  const _ChickenHeader({required this.chicken});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: chicken.photoPath != null
                  ? Image.file(File(chicken.photoPath!),
                      width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.pets,
                          size: 40,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chicken.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    chicken.displayTerm,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  if (!chicken.isActive) ...[
                    const SizedBox(height: 6),
                    _StatusBadge(chicken: chicken),
                  ],
                  if (chicken.breed != null) ...[
                    const SizedBox(height: 4),
                    Text(chicken.breed!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14)),
                  ],
                  if (chicken.estimatedHatchDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${chicken.isApproximateAge ? '~' : ''}${chicken.ageDisplay} old'
                      '${chicken.isApproximateAge ? ' (est.)' : ''}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Text(
                      chicken.acquiredVia == 'hatched'
                          ? 'Hatched ${DateFormat('d MMM yyyy').format(chicken.estimatedHatchDate!)}'
                          : 'Bought ${DateFormat('d MMM yyyy').format(chicken.buyDate!)}',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                  if (chicken.eggColorCategory != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: eggColorSwatch(chicken.eggColorCategory!),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lays ${chicken.eggColorCategory!.replaceAll('_', ' ')} eggs',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                  if (chicken.color != null) ...[
                    const SizedBox(height: 4),
                    Text(chicken.color!,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Chicken chicken;
  const _StatusBadge({required this.chicken});

  @override
  Widget build(BuildContext context) {
    final label = switch (chicken.status) {
      'deceased' => 'Deceased',
      'missing' => 'Missing',
      'slaughtered' => 'Slaughtered',
      _ => chicken.status,
    };
    final color = switch (chicken.status) {
      'deceased' => Colors.red.shade700,
      'missing' => Colors.orange.shade700,
      'slaughtered' => Colors.brown.shade600,
      _ => Colors.grey,
    };
    final dateStr = chicken.statusDate != null
        ? ' · ${DateFormat('d MMM yyyy').format(chicken.statusDate!)}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label$dateStr',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EggStatsCard extends StatelessWidget {
  final List<EggRecord> records;
  final Chicken chicken;
  const _EggStatsCard({required this.records, required this.chicken});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      final isMale = chicken.gender == 'male';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isMale
                ? 'No egg records — ${chicken.displayTerm.toLowerCase()}s don\'t lay!'
                : 'No eggs recorded for this ${chicken.displayTerm.toLowerCase()} yet.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final total = records.length;
    final avgWeight =
        records.map((r) => r.weightGrams).reduce((a, b) => a + b) /
            records.length;
    final latest = records.first;
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final eggsThisWeek = records
        .where((r) => !r.date
            .isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)))
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Egg History',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(label: 'Total', value: '$total'),
                _MiniStat(
                    label: 'Avg weight',
                    value: '${avgWeight.toStringAsFixed(1)}g'),
                _MiniStat(label: 'This week', value: '$eggsThisWeek'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last egg: ${DateFormat('d MMM yyyy').format(latest.date)}',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EggHistoryList extends StatelessWidget {
  final List<EggRecord> records;
  const _EggHistoryList({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Eggs',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...records.map((r) => _EggRow(record: r)),
          ],
        ),
      ),
    );
  }
}

class _EggRow extends StatelessWidget {
  final EggRecord record;
  const _EggRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: eggColorSwatch(record.eggColorCategory),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 10),
          Text(DateFormat('d MMM yyyy').format(record.date),
              style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text('${record.weightGrams.toStringAsFixed(1)}g',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(record.sizeGrade,
                style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
