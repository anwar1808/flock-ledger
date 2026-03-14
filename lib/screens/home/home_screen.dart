import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/chick_batch.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../journal/chick_batch_screen.dart';
import '../journal/journal_screen.dart';
import '../journal/entry_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          final activeBatches = provider.batches
              .where((b) => b.status == 'incubating' || b.status == 'hatching')
              .toList();
          final recentEntries = provider.entries.take(3).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(greeting: _greeting()),
              ),
              if (activeBatches.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Needs attention',
                    icon: Icons.notifications_active_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (activeBatches.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _IncubationCard(batch: activeBatches[i]),
                      childCount: activeBatches.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent notes',
                  icon: Icons.edit_note_outlined,
                  trailing: recentEntries.isNotEmpty
                      ? TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const JournalScreen()),
                          ),
                          child: const Text('View all'),
                        )
                      : null,
                ),
              ),
              if (recentEntries.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No journal notes yet. Tap + to add your first one.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _RecentEntryCard(
                        entry: recentEntries[i],
                      ),
                      childCount: recentEntries.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_home',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntryEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  const _Header({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24, 20, 24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          const Text('🐓', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: effectiveColor,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Incubation card ─────────────────────────────────────────────────────────

class _IncubationCard extends StatelessWidget {
  final ChickBatch batch;
  const _IncubationCard({required this.batch});

  /// Returns the next upcoming milestone and days until it.
  ({String label, int daysUntil}) _nextMilestone() {
    final day = batch.daysIncubated;
    if (day < 7) return (label: 'Candling (D7)', daysUntil: 7 - day);
    if (day < 18) return (label: 'Lockdown (D18)', daysUntil: 18 - day);
    if (day < 21) return (label: 'Hatch day! (D21)', daysUntil: 21 - day);
    return (label: 'Hatch day!', daysUntil: 0);
  }

  @override
  Widget build(BuildContext context) {
    final milestone = _nextMilestone();
    final isUrgent = milestone.daysUntil <= 1;
    final urgentColor = Theme.of(context).colorScheme.error;
    final normalColor = Theme.of(context).colorScheme.primary;
    final cardColor = isUrgent
        ? urgentColor.withValues(alpha: 0.08)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final urgencyText = milestone.daysUntil == 0
        ? 'TODAY'
        : milestone.daysUntil == 1
            ? 'Tomorrow'
            : 'In ${milestone.daysUntil} days';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? BorderSide(color: urgentColor.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChickBatchScreen(batchId: batch.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (batch.breed != null)
                          Text(
                            batch.breed!,
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
                        'Day ${batch.daysIncubated} of 21',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isUrgent ? urgentColor : normalColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${milestone.label} · $urgencyText',
                        style: TextStyle(
                          fontSize: 11,
                          color: isUrgent ? urgentColor : Colors.grey.shade600,
                          fontWeight: isUrgent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: batch.incubationProgress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? urgentColor : normalColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent entry card ────────────────────────────────────────────────────────

class _RecentEntryCard extends StatelessWidget {
  final JournalEntry entry;
  const _RecentEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('d MMM').format(entry.date),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
