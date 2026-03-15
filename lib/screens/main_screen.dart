import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chicken_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/egg_provider.dart';
import '../widgets/hen_icon.dart';
import '../widgets/coop_icon.dart';
import 'home/home_screen.dart';
import 'eggs/egg_tracker_screen.dart';
import 'flock/flock_screen.dart';
import 'insights/insights_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<ChickenProvider>().loadChickens(),
      context.read<JournalProvider>().loadAll(),
      context.read<EggProvider>().loadRecords(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const EggTrackerScreen(),
      const FlockScreen(),
      const InsightsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: CoopIcon(),
            selectedIcon: CoopIcon(),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.egg_outlined),
            selectedIcon: Icon(Icons.egg),
            label: 'Eggs',
          ),
          NavigationDestination(
            icon: HenIcon(),
            selectedIcon: HenIcon(),
            label: 'Flock',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
