import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'providers/custom_lists_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/inventory_ffi_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the C++ shared library.
  final ffi = InventoryFfiService()..load();

  // Open (or create) the local database.
  final db = DatabaseService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(db: db, ffi: ffi),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomListsProvider(db: db, ffi: ffi),
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
          seedColor: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
