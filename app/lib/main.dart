import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/cache/last_seen_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/supabase/supabase_init.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/errors_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/supabase_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/auth_view.dart';
import 'ui/features/errors/view_models/errors_view_model.dart';
import 'ui/features/errors/views/errors_view.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/settings/views/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  try {
    await initSupabase();
  } catch (e) {
    // Позволяем запуститься без Supabase для верстки (покажет ошибку в UI)
    debugPrint('Supabase init skipped: $e');
  }

  LastSeenService? lastSeen;
  try {
    lastSeen = await LastSeenService.create();
  } catch (e) {
    debugPrint('LastSeen init failed: $e');
  }
  final supabaseService = SupabaseService(Supabase.instance.client);
  final authService = AuthService(Supabase.instance.client);
  final authRepo = AuthRepository(service: authService);
  final errorsRepo = ErrorsRepository(service: supabaseService, cache: lastSeen);
  final settingsRepo = SettingsRepository(service: supabaseService);
  final notificationService = NotificationService(supabaseService: supabaseService);
  // не блокируем старт если Firebase не настроен
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint('Notifications init skipped: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<AuthService>.value(value: authService),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<ErrorsRepository>.value(value: errorsRepo),
        Provider<SettingsRepository>.value(value: settingsRepo),
        ChangeNotifierProvider(create: (_) => AuthViewModel(repository: authRepo)),
        ChangeNotifierProvider(create: (_) => ErrorsViewModel(repository: errorsRepo)..load()..subscribeRealtime()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(repository: settingsRepo)),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    if (!authVm.isAuthenticated) {
      return MaterialApp(
        title: '1C Monitor',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
        home: const AuthView(),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp(
      title: '1C Monitor',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: const [ErrorsView(), SettingsView()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Ошибки'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
