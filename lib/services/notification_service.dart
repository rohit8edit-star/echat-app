import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'echat_messages',
    'E-Chat Messages',
    description: 'E-Chat messages and calls',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(showLocalNotification);

    final token = await _fcm.getToken();
    if (token != null) await ApiService.saveFcmToken(token);
    _fcm.onTokenRefresh.listen(ApiService.saveFcmToken);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    final isCall = message.data['type'] == 'call';
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: isCall,
          category: isCall
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }
}
