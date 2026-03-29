import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../providers/chicken_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/sexing_provider.dart';
import '../../models/chicken.dart';
import '../../models/egg_record.dart';
import '../../models/sexing_assessment.dart';
import '../../utils/egg_color_matcher.dart';
import 'chicken_edit_screen.dart';
import '../../widgets/hen_icon.dart';
import '../journal/chick_sexing_screen.dart';

class ChickenDetailScreen extends StatefulWidget {
  final String chickenId;
  const ChickenDetailScreen({super.key, required this.chickenId});

  @override
  State<ChickenDetailScreen> createState() => _ChickenDetailScreenState();
}

class _ChickenDetailScreenState extends State<ChickenDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexingProvider>().loadForChicken(widget.chickenId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChickenProvider, EggProvider, SexingProvider>(
      builder: (context, chickenProvider, eggProvider, sexingProvider, _) {
        final chicken = chickenProvider.getById(widget.chickenId);
        if (chicken == null) {
          return const Scaffold(
            body: Center(child: Text('Chicken not found')),
          );
        }
        final records = eggProvider.recordsForChicken(widget.chickenId);
        records.sort((a, b) => b.date.compareTo(a.date));
        final assessments = sexingProvider.forChicken(widget.chickenId);

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
              if (assessments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SexingHistorySection(
                  assessments: assessments,
                  chickenId: widget.chickenId,
                ),
              ],
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

  void _openLightbox(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _PhotoLightbox(photoPath: chicken.photoPath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: chicken.photoPath != null
                  ? () => _openLightbox(context)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: chicken.photoPath != null
                    ? Image.file(File(chicken.photoPath!),
                        width: 80, height: 80, fit: BoxFit.cover)
                    : Container(
                        width: 80,
                        height: 80,
                        color:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Center(
                          child: HenIcon(
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
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
                    chicken.isProbableGender
                        ? 'Probably ${chicken.displayTerm}'
                        : chicken.displayTerm,
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _InfoChip(chicken.purposeLabel),
                      if (chicken.status == 'slaughtered' &&
                          chicken.liveWeightGrams != null)
                        _InfoChip(
                            'Live: ${chicken.liveWeightGrams!.toStringAsFixed(0)}g'),
                      if (chicken.status == 'slaughtered' &&
                          chicken.dressedWeightGrams != null)
                        _InfoChip(
                            'Dressed: ${chicken.dressedWeightGrams!.toStringAsFixed(0)}g'),
                      if (chicken.dressingPercentage != null)
                        _InfoChip(
                            '${chicken.dressingPercentage!.toStringAsFixed(0)}% dressing'),
                    ],
                  ),
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

// ─── Info chip ───────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    );
  }
}

// ─── Photo lightbox ───────────────────────────────────────────────────────────

class _PhotoLightbox extends StatelessWidget {
  final String photoPath;
  const _PhotoLightbox({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 200) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Hero(
            tag: photoPath,
            child: InteractiveViewer(
              child: Image.file(File(photoPath)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sexing history ───────────────────────────────────────────────────────────

class _SexingHistorySection extends StatelessWidget {
  final List<SexingAssessment> assessments;
  final String chickenId;

  const _SexingHistorySection({
    required this.assessments,
    required this.chickenId,
  });

  String _genderLabel(String gender) => switch (gender) {
        'female' => 'Female',
        'male' => 'Male',
        'probably_female' => 'Probably female',
        'probably_male' => 'Probably male',
        'uncertain' => 'Uncertain',
        _ => 'Unknown',
      };

  Color _genderColor(String gender) => switch (gender) {
        'female' || 'probably_female' => const Color(0xFFE91E8C),
        'male' || 'probably_male' => const Color(0xFF4A90D9),
        _ => Colors.grey,
      };

  String _genderIcon(String gender) => switch (gender) {
        'female' || 'probably_female' => '♀',
        'male' || 'probably_male' => '♂',
        _ => '?',
      };

  Future<void> _confirmDelete(
      BuildContext context, SexingAssessment a) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Delete this sexing result?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This will remove the record from the history. '
                'The bird\'s current gender on the flock page won\'t change.',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete result',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<SexingProvider>()
          .deleteAssessment(a.id, chickenId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sexing history',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...assessments.map((a) {
          final date = DateFormat('d MMM yyyy').format(a.assessedAt);
          final ageLabel =
              a.ageWeeks != null ? ' · Week ${a.ageWeeks}' : '';
          final claudeColor = _genderColor(a.claudeResult);
          final displayedColor = _genderColor(a.displayedGender);
          final userOverrode = a.userCall != null;

          return GestureDetector(
            onLongPress: () => _confirmDelete(context, a),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$date$ageLabel',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                        const Spacer(),
                        Text(
                          '${_genderIcon(a.displayedGender)} ${_genderLabel(a.displayedGender)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: displayedColor,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: claudeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Claude: ${_genderLabel(a.claudeResult)} · ${a.claudeConfidence}',
                            style: TextStyle(
                                fontSize: 11, color: claudeColor),
                          ),
                        ),
                        if (userOverrode) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Your call: ${_genderLabel(a.userCall!)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('Long-press a result to delete it',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade400)),
        ),
      ],
    );
  }
}
