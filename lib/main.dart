import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/sample_seeder.dart';
import 'data/models/pc_part_model.dart';
import 'data/models/configuration_model.dart';
import 'presentation/screens/prompt_screen.dart';
import 'presentation/providers/isar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar
  Isar? isar;
  
  try {
    if (kIsWeb) {
      isar = null;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [PCPartModelSchema, ConfigurationModelSchema],
        directory: dir.path,
      );
    }

    // Seed data
    await SampleSeeder.seedParts(isar);
  } catch (e, stack) {
    debugPrint('CRITICAL ERROR DURING INITIALIZATION: $e');
    debugPrint(stack.toString());
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Config',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const PromptScreen(),
    );
  }
}
