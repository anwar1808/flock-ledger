import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../providers/chicken_provider.dart';
import '../../providers/egg_provider.dart';
import '../../models/chicken.dart';
import '../../models/flock_group.dart';
import 'chicken_detail_screen.dart';
import 'chicken_edit_screen.dart';
import 'flock_group_edit_screen.dart';
import 'loss_event_screen.dart';
import 'batch_hatch_screen.dart';
import '../../widgets/hen_icon.dart';
import '../../widgets/skull_icon.dart';

class FlockScreen extends StatelessWidget {
  const FlockScreen({super.key});

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock'),
        actions: [
          IconButton(
            icon: const SkullIcon(),
            tooltip: 'Log loss event',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const LossEventScreen())),
          ),
          IconButton(
            icon: const HenIcon(),
            tooltip: 'Manage groups',
            onPressed: () => _manageGroups(context),
          ),
        ],
      ),
      body: Consumer2<ChickenProvider, EggProvider>(
        builder: (context, chickenProvider, eggProvider, _) {
          if (chickenProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final chickens = chickenProvider.chickens;
          final groups = chickenProvider.flockGroups;

          if (chickens.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HenIcon(size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No birds yet — add your first one!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a Bird'),
                    onPressed: () => _showAddSheet(context),
                  ),
                ],
              ),
            );
          }

          // Build active sections: one per group, then ungrouped
          final sections = <_Section>[];
          for (final group in groups) {
            final members = chickenProvider
                .chickensInGroup(group.id)
                .where((c) => c.status == 'active')
                .toList();
            if (members.isNotEmpty) {
              sections.add(_Section(group: group, chickens: members));
            }
          }
          final ungrouped = chickenProvider.ungroupedChickens
              .where((c) => c.status == 'active')
              .toList();
          if (ungrouped.isNotEmpty) {
            sections.add(_Section(group: null, chickens: ungrouped));
          }

          final archived = chickenProvider.archivedChickens;

          // Build flat list of widgets
          final items = <Widget>[];
          for (final section in sections) {
            items.add(_GroupHeader(
              section: section,
              hexColor: section.group != null
                  ? _hexColor(section.group!.colorHex)
                  : Colors.grey.shade400,
              onLongPress: section.group != null
                  ? () => _showGroupActions(
                        context,
                        section.group!,
                        section.chickens.length,
                      )
                  : null,
            ));
            for (final chicken in section.chickens) {
              items.add(_ChickenCard(
                chicken: chicken,
                eggsThisWeek:
                    eggProvider.eggsThisWeek(chickenId: chicken.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChickenDetailScreen(chickenId: chicken.id)),
                ),
                onLongPress: () =>
                    _showBirdActions(context, chicken),
              ));
            }
          }

          // Archived section
          if (archived.isNotEmpty) {
            items.add(_ArchivedSection(
              birds: archived,
              eggProvider: eggProvider,
            ));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: items,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add one bird'),
              subtitle: const Text('Name, breed, age, photo…'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ChickenEditScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.egg_outlined),
              title: const Text('Add from a hatch'),
              subtitle: const Text('Create multiple birds from the same clutch'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const BatchHatchScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBirdActions(BuildContext context, Chicken chicken) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            ListTile(
              title: Text(chicken.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(chicken.displayTerm),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChickenEditScreen(chicken: chicken)));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteBird(context, chicken);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBird(BuildContext context, Chicken chicken) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bird?'),
        content: Text(
            'This will permanently delete ${chicken.name} and all their egg records. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ChickenProvider>().deleteChicken(chicken.id);
              context.read<EggProvider>().removeRecordsForChicken(chicken.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGroupActions(BuildContext context, FlockGroup group, int birdCount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            ListTile(
              title: Text(group.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$birdCount ${birdCount == 1 ? 'bird' : 'birds'}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Delete flock',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteGroup(context, group, birdCount);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, FlockGroup group, int birdCount) {
    final birdWord = birdCount == 1 ? 'bird' : 'birds';
    // First confirmation
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${group.name}"?'),
        content: Text(
            'You are about to delete this flock and $birdCount $birdWord inside it. '
            'All egg records for these birds will also be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              // Second confirmation
              _finalConfirmDeleteGroup(context, group, birdCount);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _finalConfirmDeleteGroup(BuildContext context, FlockGroup group, int birdCount) {
    final birdWord = birdCount == 1 ? 'bird' : 'birds';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: Text(
            'This will permanently erase "${group.name}", all $birdCount $birdWord, '
            'and every egg record linked to them.\n\n'
            'There is no way to get this back.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedIds = await context
                  .read<ChickenProvider>()
                  .deleteFlockGroupWithBirds(group.id);
              final eggProvider = context.read<EggProvider>();
              for (final id in deletedIds) {
                eggProvider.removeRecordsForChicken(id);
              }
            },
            child: const Text('Yes, delete everything'),
          ),
        ],
      ),
    );
  }

  void _manageGroups(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ManageGroupsSheet(),
    );
  }
}

// ─── Data helper ─────────────────────────────────────────────────────────────

class _Section {
  final FlockGroup? group;
  final List<Chicken> chickens;
  _Section({required this.group, required this.chickens});
}

// ─── Group header (with inline rename) ───────────────────────────────────────

class _GroupHeader extends StatefulWidget {
  final _Section section;
  final Color hexColor;
  final VoidCallback? onLongPress;

  const _GroupHeader({
    required this.section,
    required this.hexColor,
    this.onLongPress,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.section.group?.name ?? 'Ungrouped');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    final provider = context.read<ChickenProvider>();
    if (widget.section.group != null) {
      await provider.updateFlockGroup(
          widget.section.group!.copyWith(name: newName));
    } else {
      // "Ungrouped" → create a real group and move chickens into it
      await provider.nameUngroupedChickens(name: newName);
    }
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.section.group?.name ?? 'Ungrouped';
    final count = widget.section.chickens.length;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: widget.hexColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          if (_editing)
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _commit(),
                onTapOutside: (_) => _commit(),
              ),
            )
          else ...[
            GestureDetector(
              onTap: () {
                _controller.text = name;
                setState(() => _editing = true);
              },
              onLongPress: widget.onLongPress,
              child: Text(
                name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count ${count == 1 ? 'bird' : 'birds'}',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const Spacer(),
            if (widget.section.group != null)
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlockGroupEditScreen(
                        group: widget.section.group),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      size: 16, color: Colors.grey.shade500),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Manage groups bottom sheet ───────────────────────────────────────────────

class _ManageGroupsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChickenProvider>(
      builder: (context, provider, _) {
        final groups = provider.flockGroups;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Flock Groups',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New group'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FlockGroupEditScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (groups.isEmpty && provider.ungroupedChickens.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No groups yet.',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              else ...[
                ...groups.map((g) {
                  final hex = g.colorHex.replaceAll('#', '');
                  final color = Color(int.parse('FF$hex', radix: 16));
                  final count = provider.chickensInGroup(g.id).length;
                  return ListTile(
                    leading: CircleAvatar(
                        radius: 10, backgroundColor: color),
                    title: Text(g.name),
                    subtitle: Text(
                        '$count ${count == 1 ? 'bird' : 'birds'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                FlockGroupEditScreen(group: g)),
                      );
                    },
                  );
                }),
                // Ungrouped row
                if (provider.ungroupedChickens.isNotEmpty)
                  _UngroupedSheetTile(
                      count: provider.ungroupedChickens.length),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─── Ungrouped tile in manage sheet ──────────────────────────────────────────

class _UngroupedSheetTile extends StatelessWidget {
  final int count;
  const _UngroupedSheetTile({required this.count});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 10, backgroundColor: Colors.grey.shade400),
      title: const Text('Ungrouped'),
      subtitle: Text('$count ${count == 1 ? 'bird' : 'birds'} · tap to name this group'),

      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _promptRename(context),
    );
  }

  void _promptRename(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Main Flock',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _save(ctx, controller.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => _save(ctx, controller.text),
              child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext ctx, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(ctx); // close dialog
    Navigator.pop(ctx); // close sheet
    await ctx.read<ChickenProvider>().nameUngroupedChickens(name: trimmed);
  }
}

// ─── Archived section ─────────────────────────────────────────────────────────

class _ArchivedSection extends StatelessWidget {
  final List<Chicken> birds;
  final EggProvider eggProvider;

  const _ArchivedSection({
    required this.birds,
    required this.eggProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Archived (${birds.length})',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey),
        ),
        children: birds.map((bird) {
          final statusLabel = switch (bird.status) {
            'deceased' => 'Deceased',
            'missing' => 'Missing',
            'slaughtered' => 'Slaughtered',
            _ => 'Archived',
          };
          final statusDate = bird.statusDate != null
              ? ' · ${_fmtDate(bird.statusDate!)}'
              : '';
          return Opacity(
            opacity: 0.6,
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChickenDetailScreen(chickenId: bird.id)),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: bird.photoPath != null
                            ? Image.file(
                                File(bird.photoPath!),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade200,
                                child: HenIcon(size: 28, color: Colors.grey.shade400),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bird.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            if (bird.breed != null)
                              Text(bird.breed!,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                            Text('$statusLabel$statusDate',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ─── Chicken card (unchanged visuals) ────────────────────────────────────────

class _ChickenCard extends StatelessWidget {
  final Chicken chicken;
  final int eggsThisWeek;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChickenCard({
    required this.chicken,
    required this.eggsThisWeek,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: chicken.photoPath != null
                    ? Image.file(
                        File(chicken.photoPath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Center(
                          child: HenIcon(
                            size: 32,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chicken.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if (chicken.breed != null)
                      Text(chicken.breed!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    if (!chicken.isActive)
                      const Text('Inactive',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (eggsThisWeek > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$eggsThisWeek this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'No eggs this week',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
