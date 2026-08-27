import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (url.isEmpty || anonKey.isEmpty) {
    // Для локалки: supabase start выдаст URL/anonKey — прокидывай через --dart-define
    // flutter run --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=xxx
    throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY не заданы (dart-define)');
  }
  // ignore: deprecated_member_use — publishableKey в новых версиях, anonKey пока работает
  await Supabase.initialize(url: url, anonKey: anonKey);
}
