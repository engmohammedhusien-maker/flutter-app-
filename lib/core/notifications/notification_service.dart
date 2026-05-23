import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// خدمة مسؤولة عن كل ما يتعلق بالإشعارات (SRP - SOLID)
class NotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService()
      : _firebaseMessaging = FirebaseMessaging.instance,
        _localNotifications = FlutterLocalNotificationsPlugin();

  /// تهيئة الإشعارات المحلية (لإظهارها داخل التطبيق عند ورود إشعار)
  Future<void> initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  /// طلب صلاحية استقبال الإشعارات من المستخدم
  Future<bool> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// الحصول على رمز FCM للجهاز الحالي (سنرسله إلى السيرفر لاحقاً)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// الاستماع لتحديثات الرمز
  void onTokenRefresh(void Function(String token) callback) {
    _firebaseMessaging.onTokenRefresh.listen(callback);
  }

  /// التعامل مع الإشعارات عندما يكون التطبيق في المقدمة
  void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // عرض إشعار محلي
      _showLocalNotification(message);
    });
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'الإشعارات العامة',
      channelDescription: 'قناة الإشعارات الافتراضية',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'إشعار جديد',
      message.notification?.body ?? '',
      details,
      payload: message.data['route'], // لاستخدامه في التوجيه
    );
  }
}
