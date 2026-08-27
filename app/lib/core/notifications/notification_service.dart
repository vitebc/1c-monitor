import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/services/supabase_service.dart';

/// Обёртка над FCM + local_notifications
/// - Запрашивает пермишены (POST_NOTIFICATIONS на Android 13+)
/// - Получает FCM token и upsert в device_tokens
/// - Показывает локальное уведомление когда FCM пришёл в фоне
class NotificationService {
  NotificationService({required SupabaseService supabaseService}) : _supabase = supabaseService;
  final SupabaseService _supabase;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await Firebase.initializeApp();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Android 13+ пермишен
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // токен -> Supabase device_tokens
    final token = await messaging.getToken();
    if (token != null) {
      final platform = _platformString();
      await _supabase.upsertDeviceToken(token: token, platform: platform);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      await _supabase.upsertDeviceToken(token: t, platform: _platformString());
    });

    // foreground: показываем локально
    FirebaseMessaging.onMessage.listen((msg) async {
      final title = msg.notification?.title ?? msg.data['event_name'] ?? 'Новая ошибка';
      final body = msg.notification?.body ?? msg.data['base'] ?? '';
      await _local.show(
        msg.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails('errors', 'Ошибки 1С', importance: Importance.high),
          iOS: DarwinNotificationDetails(),
        ),
        payload: msg.data['error_id'],
      );
    });
  }

  String _platformString() {
    // упрощённо — определяется при сборке flutter run -d
    // можно уточнить через defaultTargetPlatform
    return 'android';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // фоновая обработка — система сама покажет уведомление, если notification есть
}
