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
            icon: const Icon(Icons.folder_outlined),
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
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hens yet — add your first girl!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a Chicken'),
                    onPressed: () => _openAddChicken(context),
                  ),
                ],
              ),
            );
          }

          // Build sections: one per group, then ungrouped
          final sections = <_Section>[];

          for (final group in groups) {
            final members = chickenProvider.chickensInGroup(group.id);
            if (members.isNotEmpty) {
              sections.add(_Section(group: group, chickens: members));
            }
          }

          final ungrouped = chickenProvider.ungroupedChickens;
          if (ungrouped.isNotEmpty) {
            sections.add(_Section(group: null, chickens: ungrouped));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: sections.fold<int>(
                0, (sum, s) => sum + 1 + s.chickens.length),
            itemBuilder: (context, index) {
              // Map flat index to section + item
              int cursor = 0;
              for (final section in sections) {
                if (index == cursor) {
                  // Section header
                  return _GroupHeader(
                    section: section,
                    hexColor: section.group != null
                        ? _hexColor(section.group!.colorHex)
                        : Colors.grey.shade400,
                    onEdit: section.group != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlockGroupEditScreen(
                                    group: section.group),
                              ),
                            )
                        : null,
                  );
                }
                cursor++;
                final localIndex = index - cursor;
                if (localIndex < section.chickens.length) {
                  final chicken = section.chickens[localIndex];
                  return _ChickenCard(
                    chicken: chicken,
                    eggsThisWeek:
                        eggProvider.eggsThisWeek(chickenId: chicken.id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ChickenDetailScreen(chickenId: chicken.id)),
                    ),
                  );
                }
                cursor += section.chickens.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddChicken(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddChicken(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChickenEditScreen()),
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

// ─── Group header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final _Section section;
  final Color hexColor;
  final VoidCallback? onEdit;

  const _GroupHeader({
    required this.section,
    required this.hexColor,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = section.group?.name ?? 'Ungrouped';
    final count = section.chickens.length;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: hexColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'hen' : 'hens'}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const Spacer(),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: Colors.grey.shade500),
              ),
            ),
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
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No groups yet.',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              else
                ...groups.map((g) {
                  final hex = g.colorHex.replaceAll('#', '');
                  final color = Color(int.parse('FF$hex', radix: 16));
                  final count = provider.chickensInGroup(g.id).length;
                  return ListTile(
                    leading: CircleAvatar(
                        radius: 10, backgroundColor: color),
                    title: Text(g.name),
                    subtitle: Text(
                        '$count ${count == 1 ? 'hen' : 'hens'}'),
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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─── Chicken card (unchanged visuals) ────────────────────────────────────────

class _ChickenCard extends StatelessWidget {
  final Chicken chicken;
  final int eggsThisWeek;
  final VoidCallback onTap;

  const _ChickenCard({
    required this.chicken,
    required this.eggsThisWeek,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
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
                        child: Icon(
                          Icons.pets,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
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
