import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/egg_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../models/chicken.dart';
import '../../models/egg_record.dart';
import '../../utils/egg_color_matcher.dart';

class EggStatsScreen extends StatefulWidget {
  const EggStatsScreen({super.key});

  @override
  State<EggStatsScreen> createState() => _EggStatsScreenState();
}

class _EggStatsScreenState extends State<EggStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChickenId; // null = all chickens combined

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Charts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Production'),
            Tab(text: 'Weights'),
          ],
        ),
      ),
      body: Consumer2<EggProvider, ChickenProvider>(
        builder: (context, eggProvider, chickenProvider, _) {
          final chickens = chickenProvider.chickens;
          final allRecords = eggProvider.records;

          if (allRecords.isEmpty) {
            return const Center(
              child: Text('No egg data yet.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return Column(
            children: [
              // Chicken selector chips
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All hens'),
                        selected: _selectedChickenId == null,
                        onSelected: (_) =>
                            setState(() => _selectedChickenId = null),
                        showCheckmark: false,
                      ),
                    ),
                    ...chickens
                        .where((c) => allRecords
                            .any((r) => r.chickenId == c.id))
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: c.eggColorCategory != null
                                    ? CircleAvatar(
                                        radius: 8,
                                        backgroundColor:
                                            eggColorSwatch(c.eggColorCategory!),
                                      )
                                    : null,
                                label: Text(c.name),
                                selected: _selectedChickenId == c.id,
                                onSelected: (_) => setState(
                                    () => _selectedChickenId = c.id),
                                showCheckmark: false,
                              ),
                            )),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProductionTab(
                      records: allRecords,
                      chickens: chickens,
                      selectedChickenId: _selectedChickenId,
                      eggProvider: eggProvider,
                    ),
                    _WeightsTab(
                      records: allRecords,
                      chickens: chickens,
                      selectedChickenId: _selectedChickenId,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// PRODUCTION TAB
// ─────────────────────────────────────────

class _ProductionTab extends StatelessWidget {
  final List<EggRecord> records;
  final List<Chicken> chickens;
  final String? selectedChickenId;
  final EggProvider eggProvider;

  const _ProductionTab({
    required this.records,
    required this.chickens,
    required this.selectedChickenId,
    required this.eggProvider,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedChickenId != null
        ? records.where((r) => r.chickenId == selectedChickenId).toList()
        : records;

    // Weekly data
    final weeklyData = _buildWeeklyData(filtered);

    // Size grade distribution
    final grades = <String, int>{};
    for (final r in filtered) {
      grades[r.sizeGrade] = (grades[r.sizeGrade] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniStat(label: 'Total', value: filtered.length.toString()),
                _MiniStat(
                    label: 'This week',
                    value: eggProvider
                        .eggsThisWeek(chickenId: selectedChickenId)
                        .toString()),
                _MiniStat(
                    label: 'Avg/week',
                    value: weeklyData.isEmpty
                        ? '—'
                        : (weeklyData
                                    .map((e) => e.value)
                                    .reduce((a, b) => a + b) /
                                weeklyData.length)
                            .toStringAsFixed(1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weekly bar chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eggs per week (last 12 weeks)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: (weeklyData.isEmpty
                              ? 7
                              : weeklyData
                                      .map((e) => e.value)
                                      .reduce((a, b) => a > b ? a : b) +
                                  1)
                          .toDouble(),
                      barGroups: weeklyData.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 14,
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
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= weeklyData.length) {
                                return const SizedBox.shrink();
                              }
                              final date = weeklyData[idx].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('d/M').format(date),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Size grade breakdown
        if (grades.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Size Grade Distribution',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...const [
                    'Peewee', 'Small', 'Medium', 'Large', 'XL', 'Jumbo'
                  ].map((grade) {
                    final count = grades[grade] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    final pct = count / filtered.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 60,
                              child: Text(grade,
                                  style: const TextStyle(fontSize: 13))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context)
                                        .colorScheme
                                        .primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<MapEntry<DateTime, int>> _buildWeeklyData(List<EggRecord> recs) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, int>>[];
    for (int w = 11; w >= 0; w--) {
      final monday = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      final weekStart = DateTime(monday.year, monday.month, monday.day);
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = recs
          .where((r) =>
              !r.date.isBefore(weekStart) && r.date.isBefore(weekEnd))
          .length;
      result.add(MapEntry(weekStart, count));
    }
    return result;
  }
}

// ─────────────────────────────────────────
// WEIGHTS TAB
// ─────────────────────────────────────────

class _WeightsTab extends StatelessWidget {
  final List<EggRecord> records;
  final List<Chicken> chickens;
  final String? selectedChickenId;

  const _WeightsTab({
    required this.records,
    required this.chickens,
    required this.selectedChickenId,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedChickenId != null
        ? records.where((r) => r.chickenId == selectedChickenId).toList()
        : records;

    if (filtered.isEmpty) {
      return const Center(
          child: Text('No data for this selection.',
              style: TextStyle(color: Colors.grey)));
    }

    final sorted = List<EggRecord>.from(filtered)
      ..sort((a, b) => a.date.compareTo(b.date));

    final avgWeight = sorted.map((r) => r.weightGrams).reduce((a, b) => a + b) /
        sorted.length;
    final minWeight =
        sorted.map((r) => r.weightGrams).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        sorted.map((r) => r.weightGrams).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniStat(
                    label: 'Average',
                    value: '${avgWeight.toStringAsFixed(1)}g'),
                _MiniStat(
                    label: 'Min', value: '${minWeight.toStringAsFixed(1)}g'),
                _MiniStat(
                    label: 'Max', value: '${maxWeight.toStringAsFixed(1)}g'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weight over time line chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight Over Time',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: sorted.asMap().entries.map((e) {
                            return FlSpot(
                                e.key.toDouble(), e.value.weightGrams);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: sorted.length <= 30,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                        // Average line
                        LineChartBarData(
                          spots: [
                            FlSpot(0, avgWeight),
                            FlSpot(
                                sorted.length.toDouble() - 1, avgWeight),
                          ],
                          color: Colors.orange.withOpacity(0.6),
                          barWidth: 1,
                          dashArray: [5, 5],
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}g',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                        width: 20,
                        height: 2,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    const Text('Weight', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 16),
                    Container(width: 20, height: 2, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text('Average', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
