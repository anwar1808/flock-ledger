import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/chick_batch.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../providers/egg_provider.dart';
import '../journal/chick_batch_screen.dart';
import '../journal/journal_screen.dart';
import '../journal/entry_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Static fallback greeting — swap this one line to revert dynamic greeting ──
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Dynamic greeting — replace _greeting() call with this to revert ──
  String _buildGreeting(
      JournalProvider journal, ChickenProvider chickens, EggProvider eggs) {
    final hour = DateTime.now().hour;
    // Use hour + day-of-year as a rotating seed (changes each hour)
    final seed = (DateTime.now().difference(DateTime(DateTime.now().year)).inHours);
    final slot = seed % 10; // 0-9

    // Flock-aware lines
    final activeCount = chickens.activeChickens.length;
    final eggsThisWeek = eggs.records
        .where((r) => r.date
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    final nextHatch = journal.batches
        .where((b) => b.status == 'incubating' && !b.isOverdue)
        .fold<ChickBatch?>(null, (closest, b) {
      if (closest == null) return b;
      return b.daysRemaining < closest.daysRemaining ? b : closest;
    });

    if (slot < 4) {
      // Time-of-day farm language
      final morning = [
        'The flock is stirring',
        'Rise with the roosters',
        'First light in the yard',
        'Peak laying hours ahead',
      ];
      final afternoon = [
        'Hen o\'clock',
        'The girls are busy',
        'Prime laying time',
        'Hens are busy today',
      ];
      final evening = [
        'Roosting time soon',
        'The flock is settling',
        'Golden hour in the yard',
        'Day\'s end in the coop',
      ];
      final List<String> pool = hour < 12
          ? morning
          : hour < 18
              ? afternoon
              : evening;
      return pool[slot % pool.length];
    } else if (slot < 7) {
      // Flock-aware
      if (nextHatch != null && nextHatch.daysRemaining > 0) {
        return 'Hatch day in ${nextHatch.daysRemaining}d — ${nextHatch.name}';
      }
      if (eggsThisWeek > 0) {
        return '$eggsThisWeek egg${eggsThisWeek == 1 ? '' : 's'} logged this week';
      }
      if (activeCount > 0) {
        return '$activeCount bird${activeCount == 1 ? '' : 's'} in your flock';
      }
      // Fallback to time greeting
      return _greeting();
    } else {
      // Chicken facts & proverbs
      const facts = [
        '"Don\'t count your chickens before they hatch"',
        'A hen turns her eggs up to 50 times a day',
        'Chickens have a visual field of almost 300°',
        'Hens make over 30 distinct vocalisations',
        '"The early bird catches the worm"',
        'A freshly laid egg can stay fertile for up to 10 days',
        'Chickens can dream — they experience REM sleep',
      ];
      return facts[slot % facts.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<JournalProvider, ChickenProvider, EggProvider>(
        builder: (context, journal, chickens, eggs, _) {
          final activeBatches = journal.batches
              .where((b) => b.status == 'incubating' || b.status == 'hatching')
              .toList();
          final lockdownBatches =
              activeBatches.where((b) => b.showLockdownPrompt).toList();
          final recentEntries = journal.entries.take(3).toList();

          // Dynamic greeting — to revert: replace _buildGreeting(...) with _greeting()
          final greeting = _buildGreeting(journal, chickens, eggs);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(greeting: greeting),
              ),

              // ── Lockdown prompts ──
              if (lockdownBatches.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _LockdownPromptCard(
                        batch: lockdownBatches[i],
                        onSaved: (batch) =>
                            context.read<JournalProvider>().updateBatch(batch),
                      ),
                      childCount: lockdownBatches.length,
                    ),
                  ),
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
                      (context, i) =>
                          _IncubationCard(batch: activeBatches[i]),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                      (context, i) =>
                          _RecentEntryCard(entry: recentEntries[i]),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
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

// ─── Lockdown prompt card ─────────────────────────────────────────────────────

class _LockdownPromptCard extends StatefulWidget {
  final ChickBatch batch;
  final Future<void> Function(ChickBatch) onSaved;

  const _LockdownPromptCard({required this.batch, required this.onSaved});

  @override
  State<_LockdownPromptCard> createState() => _LockdownPromptCardState();
}

class _LockdownPromptCardState extends State<_LockdownPromptCard> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final count = int.tryParse(_controller.text.trim());
    if (count == null || count < 0) return;
    setState(() => _saving = true);
    await widget.onSaved(widget.batch.copyWith(eggsToLockdown: count));
  }

  Future<void> _dismiss() async {
    await widget.onSaved(
        widget.batch.copyWith(lockdownDismissedDate: DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final amber = const Color(0xFFD4A017);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: amber.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: amber.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lockdown today — ${widget.batch.name}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: amber),
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(Icons.close, size: 18,
                      color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'How many eggs are going into lockdown?',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. ${widget.batch.eggCount}',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: amber,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incubation card ─────────────────────────────────────────────────────────

class _IncubationCard extends StatelessWidget {
  final ChickBatch batch;
  const _IncubationCard({required this.batch});

  ({String label, int daysUntil}) _nextMilestone() {
    final day = batch.daysIncubated;
    final candleDay = 7;
    final lockdownDay = batch.incubationDays - 3;
    final hatchDay = batch.incubationDays;

    if (day < candleDay) {
      return (label: 'Candling (D$candleDay)', daysUntil: candleDay - day);
    }
    if (day < lockdownDay) {
      return (
        label: 'Lockdown (D$lockdownDay)',
        daysUntil: lockdownDay - day
      );
    }
    if (day < hatchDay) {
      return (
        label: 'Hatch day! (D$hatchDay)',
        daysUntil: hatchDay - day
      );
    }
    return (label: 'Hatch day!', daysUntil: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = batch.isOverdue;
    final urgentColor = Theme.of(context).colorScheme.error;
    final normalColor = Theme.of(context).colorScheme.primary;

    if (isOverdue) {
      // ── Overdue state: finalise prompt ──
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: urgentColor.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              BorderSide(color: urgentColor.withValues(alpha: 0.35), width: 1.5),
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
            child: Row(
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
                      const SizedBox(height: 2),
                      Text(
                        'Hatch window passed — ready to finalise?',
                        style: TextStyle(
                            color: urgentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChickBatchScreen(batchId: batch.id)),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Finalise', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Normal incubation card ──
    final milestone = _nextMilestone();
    final isUrgent = milestone.daysUntil <= 1;
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
                        'Day ${batch.daysIncubated} of ${batch.totalTrackedDays}',
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
                          color: isUrgent
                              ? urgentColor
                              : Colors.grey.shade600,
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
              // Two-tone progress bar: green (incubation) + amber (hatch window)
              LayoutBuilder(builder: (context, constraints) {
                final total = batch.totalTrackedDays;
                final incubFraction = batch.incubationDays / total;
                final progressFraction = batch.daysIncubated / total;
                final greenFraction =
                    progressFraction.clamp(0.0, incubFraction);
                final amberFraction =
                    (progressFraction - incubFraction).clamp(0.0, 1.0 - incubFraction);
                final totalW = constraints.maxWidth;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        // Track
                        Container(color: Colors.grey.shade200),
                        // Green (incubation progress)
                        if (greenFraction > 0)
                          FractionallySizedBox(
                            widthFactor: greenFraction,
                            child: Container(color: normalColor),
                          ),
                        // Amber (hatch window progress)
                        if (amberFraction > 0)
                          Positioned(
                            left: totalW * incubFraction,
                            width: totalW * amberFraction,
                            top: 0,
                            bottom: 0,
                            child: Container(
                                color: const Color(0xFFD4A017)),
                          ),
                      ],
                    ),
                  ),
                );
              }),
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
