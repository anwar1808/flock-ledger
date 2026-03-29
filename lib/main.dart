import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/database_helper.dart';
import 'providers/chicken_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/egg_provider.dart';
import 'providers/sexing_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  final settings = SettingsProvider();
  await settings.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChickenProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => EggProvider()),
        ChangeNotifierProvider(create: (_) => SexingProvider()),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: const FlockLedgerApp(),
    ),
  );
}
