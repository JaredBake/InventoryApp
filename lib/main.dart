import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'providers/inventory_provider.dart';
import 'providers/custom_lists_provider.dart';
import 'repositories/database_custom_lists_repository.dart';
import 'repositories/database_inventory_repository.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/inventory_ffi_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite uses a different factory on desktop platforms.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load the C++ shared library.
  final ffi = InventoryFfiService()..load();

  // Open (or create) the local database.
  final db = DatabaseService();
  final inventoryRepository = DatabaseInventoryRepository(db);
  final customListsRepository = DatabaseCustomListsRepository(db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(
            repository: inventoryRepository,
            ffi: ffi,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomListsProvider(
            repository: customListsRepository,
            ffi: ffi,
          ),
        ),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006064),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
