import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../providers/chicken_provider.dart';
import '../../providers/egg_provider.dart';
import '../../models/chicken.dart';
import 'chicken_detail_screen.dart';
import 'chicken_edit_screen.dart';

class FlockScreen extends StatelessWidget {
  const FlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flock')),
      body: Consumer2<ChickenProvider, EggProvider>(
        builder: (context, chickenProvider, eggProvider, _) {
          final chickens = chickenProvider.chickens;

          if (chickenProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chickens.length,
            itemBuilder: (context, index) {
              final chicken = chickens[index];
              final eggsThisWeek =
                  eggProvider.eggsThisWeek(chickenId: chicken.id);
              return _ChickenCard(
                chicken: chicken,
                eggsThisWeek: eggsThisWeek,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChickenDetailScreen(chickenId: chicken.id)),
                ),
              );
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
}

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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo or placeholder
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
