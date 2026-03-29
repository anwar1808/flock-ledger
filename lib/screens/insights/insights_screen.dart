import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/egg_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../providers/journal_provider.dart';
import '../../models/egg_record.dart';
import '../../models/chicken.dart';
import '../../models/chick_batch.dart';
import '../../utils/egg_color_matcher.dart';
import '../../widgets/hen_icon.dart';
import '../settings/settings_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Eggs'),
              Tab(text: 'Hatching'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EggsTab(),
            _HatchingTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Eggs tab ─────────────────────────────────────────────────────────────────

class _EggsTab extends StatelessWidget {
  const _EggsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<EggProvider, ChickenProvider>(
      builder: (context, eggProvider, chickenProvider, _) {
        final records = eggProvider.records;
        final chickens = chickenProvider.chickens;

        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.egg_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No egg records yet — start logging!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCards(records: records, chickens: chickens),
            const SizedBox(height: 24),
            _MonthlyProductionChart(records: records, chickens: chickens),
            const SizedBox(height: 24),
            _PerChickenTable(
                records: records,
                chickens: chickens,
                eggProvider: eggProvider),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ─── Hatching tab ─────────────────────────────────────────────────────────────

class _HatchingTab extends StatelessWidget {
  const _HatchingTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<JournalProvider, ChickenProvider>(
      builder: (context, journalProvider, chickenProvider, _) {
        final batches = journalProvider.batches;
        final hatchedBirds = chickenProvider.chickens
            .where((c) => c.acquiredVia == 'hatched')
            .toList();

        if (batches.isEmpty && hatchedBirds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.egg_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hatching data yet.\nStart a clutch in the Journal tab.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HatchSummaryCards(batches: batches),
            const SizedBox(height: 16),
            if (batches.any((b) =>
                b.status == 'incubating' ||
                b.status == 'hatching' ||
                b.status == 'raising' ||
                b.status == 'growing')) ...[
              _ActiveBatchStatus(batches: batches),
              const SizedBox(height: 16),
            ],
            if (batches.any((b) => b.hatchRate != null)) ...[
              _HatchRateTable(batches: batches),
              const SizedBox(height: 16),
            ],
            if (hatchedBirds.isNotEmpty) ...[
              _HatchedBirdsSection(birds: hatchedBirds),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }
}

// ─── Hatch summary cards ──────────────────────────────────────────────────────

class _HatchSummaryCards extends StatelessWidget {
  final List<ChickBatch> batches;
  const _HatchSummaryCards({required this.batches});

  @override
  Widget build(BuildContext context) {
    final totalBatches = batches.length;
    final totalSet = batches.fold(0, (sum, b) => sum + b.eggCount);
    final batchesWithData = batches.where((b) => b.eggsHatched != null).toList();
    final totalHatched =
        batchesWithData.fold(0, (sum, b) => sum + b.eggsHatched!);
    final avgRate = batchesWithData.isEmpty
        ? null
        : batchesWithData
                .map((b) => b.hatchRate!)
                .reduce((a, b) => a + b) /
            batchesWithData.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
              label: 'Total Clutches',
              value: totalBatches.toString(),
              icon: Icons.bubble_chart_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Eggs Set',
              value: totalSet.toString(),
              icon: Icons.egg_outlined,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
              label: 'Chicks Hatched',
              value: totalHatched.toString(),
              iconWidget: HenIcon(
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Avg Hatch Rate',
              value: avgRate != null
                  ? '${avgRate.toStringAsFixed(0)}%'
                  : '—',
              icon: Icons.percent,
            )),
          ],
        ),
      ],
    );
  }
}

// ─── Active batch status strip ────────────────────────────────────────────────

class _ActiveBatchStatus extends StatelessWidget {
  final List<ChickBatch> batches;
  const _ActiveBatchStatus({required this.batches});

  @override
  Widget build(BuildContext context) {
    final statusGroups = <String, int>{};
    for (final b in batches) {
      if (b.status == 'completed') continue;
      statusGroups[b.status] = (statusGroups[b.status] ?? 0) + 1;
    }
    if (statusGroups.isEmpty) return const SizedBox.shrink();

    final order = ['incubating', 'hatching', 'raising', 'growing'];
    final labels = {
      'incubating': 'Incubating',
      'hatching': 'Hatching',
      'raising': 'Raising',
      'growing': 'Growing',
    };
    final colors = {
      'incubating': const Color(0xFF4A90D9),
      'hatching': const Color(0xFFD4A017),
      'raising': const Color(0xFF5D8A3C),
      'growing': const Color(0xFF8A5D3C),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In Progress',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: order
                  .where((s) => statusGroups.containsKey(s))
                  .map((s) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: colors[s]!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: colors[s]!.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                statusGroups[s].toString(),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colors[s]),
                              ),
                              Text(
                                labels[s]!,
                                style: TextStyle(
                                    fontSize: 11, color: colors[s]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hatch rate per batch ─────────────────────────────────────────────────────

class _HatchRateTable extends StatelessWidget {
  final List<ChickBatch> batches;
  const _HatchRateTable({required this.batches});

  @override
  Widget build(BuildContext context) {
    final withData = batches
        .where((b) => b.hatchRate != null)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hatch Rate by Clutch',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...withData.map((b) => _HatchRateRow(batch: b)),
          ],
        ),
      ),
    );
  }
}

class _HatchRateRow extends StatelessWidget {
  final ChickBatch batch;
  const _HatchRateRow({required this.batch});

  @override
  Widget build(BuildContext context) {
    final rate = batch.hatchRate!;
    final color = rate >= 75
        ? const Color(0xFF5D8A3C)
        : rate >= 50
            ? const Color(0xFFD4A017)
            : Colors.red.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batch.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
              Text(
                '${batch.eggsHatched}/${batch.eggCount} · ${rate.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [
              DateFormat('d MMM yyyy').format(batch.startDate),
              if (batch.breed != null) batch.breed!,
              if (batch.incubatorType != null) batch.incubatorType!,
            ].join(' · '),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Hatched birds breakdown ──────────────────────────────────────────────────

class _HatchedBirdsSection extends StatelessWidget {
  final List<Chicken> birds;
  const _HatchedBirdsSection({required this.birds});

  @override
  Widget build(BuildContext context) {
    final total = birds.length;
    final active = birds.where((b) => b.isActive).length;
    final archived = total - active;
    final survivalRate = total > 0 ? active / total * 100 : 0.0;

    final female = birds.where((b) => b.gender == 'female').length;
    final male = birds.where((b) => b.gender == 'male').length;
    final unknown = birds.where((b) => b.gender == 'unknown').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Birds from Hatches',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Survival row
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        label: 'Total hatched',
                        value: total.toString(),
                        color: Theme.of(context).colorScheme.primary)),
                Expanded(
                    child: _MiniStat(
                        label: 'Still active',
                        value: active.toString(),
                        color: const Color(0xFF5D8A3C))),
                Expanded(
                    child: _MiniStat(
                        label: 'Archived',
                        value: archived.toString(),
                        color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: survivalRate / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF5D8A3C)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${survivalRate.toStringAsFixed(0)}% survival rate',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Gender breakdown
            Text('Gender breakdown',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        label: 'Female',
                        value: female.toString(),
                        color: const Color(0xFFE91E8C))),
                Expanded(
                    child: _MiniStat(
                        label: 'Male',
                        value: male.toString(),
                        color: const Color(0xFF4A90D9))),
                Expanded(
                    child: _MiniStat(
                        label: 'Unknown',
                        value: unknown.toString(),
                        color: Colors.grey)),
              ],
            ),
            if (total > 0 && unknown > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$unknown bird${unknown == 1 ? '' : 's'} still need sexing',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Egg tab widgets (unchanged logic) ────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final List<EggRecord> records;
  final List<Chicken> chickens;

  const _SummaryCards({required this.records, required this.chickens});

  @override
  Widget build(BuildContext context) {
    final totalEggs = records.length;
    final avgWeight = records.isEmpty
        ? 0.0
        : records.map((r) => r.weightGrams).reduce((a, b) => a + b) /
            records.length;

    final countByChicken = <String, int>{};
    for (final r in records) {
      if (r.chickenId != null) {
        countByChicken[r.chickenId!] =
            (countByChicken[r.chickenId!] ?? 0) + 1;
      }
    }
    String mostProductiveName = '—';
    if (countByChicken.isNotEmpty) {
      final topId = countByChicken.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      mostProductiveName =
          chickens.where((c) => c.id == topId).firstOrNull?.name ?? '—';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
              label: 'Total Eggs',
              value: totalEggs.toString(),
              icon: Icons.egg,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Avg Weight',
              value: '${avgWeight.toStringAsFixed(1)}g',
              icon: Icons.scale,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
              label: 'Active Birds',
              value: chickens.where((c) => c.isActive).length.toString(),
              iconWidget: HenIcon(
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Top Layer',
              value: mostProductiveName,
              icon: Icons.star,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  /// Either [icon] or [iconWidget] must be provided.
  final IconData? icon;
  final Widget? iconWidget;

  const _StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.iconWidget,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final iconW = iconWidget ??
        Icon(icon!, size: 20, color: color);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20, height: 20, child: iconW),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyProductionChart extends StatelessWidget {
  final List<EggRecord> records;
  final List<Chicken> chickens;

  const _MonthlyProductionChart(
      {required this.records, required this.chickens});

  @override
  Widget build(BuildContext context) {
    final monthlyData = <String, int>{};
    for (final r in records) {
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      monthlyData[key] = (monthlyData[key] ?? 0) + 1;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    final displayMonths = sortedMonths.length > 12
        ? sortedMonths.sublist(sortedMonths.length - 12)
        : sortedMonths;

    if (displayMonths.isEmpty) return const SizedBox.shrink();

    final maxY = displayMonths
        .map((m) => monthlyData[m]!)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Production',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY + 2,
                  barGroups: displayMonths.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyData[e.value]!.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= displayMonths.length) {
                            return const SizedBox.shrink();
                          }
                          final parts = displayMonths[idx].split('-');
                          final month = int.tryParse(parts[1]) ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _monthAbbr(month),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbrs = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month < abbrs.length ? abbrs[month] : '';
  }
}

class _PerChickenTable extends StatelessWidget {
  final List<EggRecord> records;
  final List<Chicken> chickens;
  final EggProvider eggProvider;

  const _PerChickenTable(
      {required this.records,
      required this.chickens,
      required this.eggProvider});

  @override
  Widget build(BuildContext context) {
    final data = <_ChickenStat>[];
    for (final chicken in chickens) {
      final recs =
          records.where((r) => r.chickenId == chicken.id).toList();
      if (recs.isEmpty) continue;
      final avgW =
          recs.map((r) => r.weightGrams).reduce((a, b) => a + b) /
              recs.length;
      final eggsThisWeek = eggProvider.eggsThisWeek(chickenId: chicken.id);
      data.add(_ChickenStat(
        chicken: chicken,
        totalEggs: recs.length,
        avgWeight: avgW,
        eggsThisWeek: eggsThisWeek,
      ));
    }
    data.sort((a, b) => b.totalEggs.compareTo(a.totalEggs));

    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Per-Hen Breakdown',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...data.map((s) => _ChickenStatRow(stat: s)),
          ],
        ),
      ),
    );
  }
}

class _ChickenStat {
  final Chicken chicken;
  final int totalEggs;
  final double avgWeight;
  final int eggsThisWeek;
  const _ChickenStat(
      {required this.chicken,
      required this.totalEggs,
      required this.avgWeight,
      required this.eggsThisWeek});
}

class _ChickenStatRow extends StatelessWidget {
  final _ChickenStat stat;
  const _ChickenStatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (stat.chicken.eggColorCategory != null)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: eggColorSwatch(stat.chicken.eggColorCategory!),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          Expanded(
            child: Text(stat.chicken.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text('${stat.totalEggs} eggs',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Text('${stat.avgWeight.toStringAsFixed(1)}g avg',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Text('${stat.eggsThisWeek}/wk',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
