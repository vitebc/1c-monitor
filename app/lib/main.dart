import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/notifications/notification_service.dart';
import 'core/supabase/supabase_init.dart';
import 'data/repositories/errors_repository.dart';
import 'data/services/supabase_service.dart';
import 'ui/features/errors/view_models/errors_view_model.dart';
import 'ui/features/errors/views/errors_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  try {
    await initSupabase();
  } catch (e) {
    // Позволяем запуститься без Supabase для верстки (покажет ошибку в UI)
    debugPrint('Supabase init skipped: $e');
  }

  final supabaseService = SupabaseService(Supabase.instance.client);
  final errorsRepo = ErrorsRepository(service: supabaseService);
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
        Provider<ErrorsRepository>.value(value: errorsRepo),
        ChangeNotifierProvider(create: (_) => ErrorsViewModel(repository: errorsRepo)..load()..subscribeRealtime()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1C Monitor',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const ErrorsView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
