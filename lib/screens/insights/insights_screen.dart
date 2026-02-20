import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/egg_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../models/egg_record.dart';
import '../../models/chicken.dart';
import '../../utils/egg_color_matcher.dart';
import '../settings/settings_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer2<EggProvider, ChickenProvider>(
        builder: (context, eggProvider, chickenProvider, _) {
          final records = eggProvider.records;
          final chickens = chickenProvider.chickens;

          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No data yet — start by adding egg records!',
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
              _MonthlyProductionChart(
                  records: records, chickens: chickens),
              const SizedBox(height: 24),
              _PerChickenTable(
                  records: records, chickens: chickens, eggProvider: eggProvider),
            ],
          );
        },
      ),
    );
  }
}

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

    // Most productive hen
    final countByChicken = <String, int>{};
    for (final r in records) {
      if (r.chickenId != null) {
        countByChicken[r.chickenId!] =
            (countByChicken[r.chickenId!] ?? 0) + 1;
      }
    }
    String mostProductiveName = '—';
    if (countByChicken.isNotEmpty) {
      final topId =
          countByChicken.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
              label: 'Hens',
              value: chickens.where((c) => c.isActive).length.toString(),
              icon: Icons.pets,
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
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
    // Group by month
    final monthlyData = <String, int>{};
    for (final r in records) {
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      monthlyData[key] = (monthlyData[key] ?? 0) + 1;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    // Show last 12 months max
    final displayMonths = sortedMonths.length > 12
        ? sortedMonths.sublist(sortedMonths.length - 12)
        : sortedMonths;

    if (displayMonths.isEmpty) return const SizedBox.shrink();

    final maxY =
        displayMonths.map((m) => monthlyData[m]!).reduce((a, b) => a > b ? a : b)
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
    // Build per-chicken stats
    final data = <_ChickenStat>[];
    for (final chicken in chickens) {
      final recs = records.where((r) => r.chickenId == chicken.id).toList();
      if (recs.isEmpty) continue;
      final avgW = recs.map((r) => r.weightGrams).reduce((a, b) => a + b) /
          recs.length;
      final eggsThisWeek =
          eggProvider.eggsThisWeek(chickenId: chicken.id);
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Text('${stat.avgWeight.toStringAsFixed(1)}g avg',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Text('${stat.eggsThisWeek}/wk',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontSize: 13)),
        ],
      ),
    );
  }
}
