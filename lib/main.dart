import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/custom_lists_provider.dart';
import 'models/auth_session.dart';
import 'repositories/database_custom_lists_repository.dart';
import 'repositories/database_inventory_repository.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/local_auth_service.dart';
import 'services/supabase_auth_service.dart';
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

  final authService = await _buildAuthService();

  // Open (or create) the local database.
  final db = DatabaseService();
  final inventoryRepository = DatabaseInventoryRepository(db);
  final customListsRepository = DatabaseCustomListsRepository(db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(service: authService),
        ),
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
      child: InventoryApp(databaseService: db),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  final DatabaseService databaseService;

  const InventoryApp({super.key, required this.databaseService});

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
      home: _AuthGate(databaseService: databaseService),
    );
  }
}

Future<AuthService> _buildAuthService() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    return SupabaseAuthService();
  }

  return LocalAuthService();
}

class _AuthGate extends StatefulWidget {
  final DatabaseService databaseService;

  const _AuthGate({required this.databaseService});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthSession? _lastSyncedSession;
  bool _syncing = false;
  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<AuthProvider>();
    if (_authProvider == provider) {
      return;
    }

    _authProvider?.removeListener(_handleAuthChanged);
    _authProvider = provider;
    _authProvider?.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    final auth = context.read<AuthProvider>();
    final currentKey = auth.session?.email ?? '';
    final lastKey = _lastSyncedSession?.email ?? '';
    if (currentKey == lastKey || _syncing) {
      return;
    }

    _syncAccountData();
  }

  Future<void> _syncAccountData() async {
    final auth = context.read<AuthProvider>();
    final session = auth.session;
    final currentKey = session?.email ?? '';
    final lastKey = _lastSyncedSession?.email ?? '';
    if (currentKey == lastKey && !_syncing) {
      return;
    }

    if (mounted) {
      setState(() {
        _syncing = true;
      });
    }

    await widget.databaseService.setScopeKey(session?.email);

    if (!mounted) return;

    if (session == null) {
      context.read<InventoryProvider>().clearItems();
      context.read<CustomListsProvider>().clearLists();
    } else {
      await context.read<InventoryProvider>().loadItems();
      if (!mounted) return;
      await context.read<CustomListsProvider>().loadLists();
    }

    if (!mounted) return;
    _lastSyncedSession = session;
    setState(() {
      _syncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading || _syncing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isSignedIn) {
      return const SignInScreen();
    }

    return const HomeScreen();
  }
}
