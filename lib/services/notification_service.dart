import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  // Callback for when notification is tapped
  Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        onNotificationTap?.call(response.payload);
      },
    );

    // Create notification channel for SMS
    const androidChannel = AndroidNotificationChannel(
      'sms_channel',
      'SMS Messages',
      description: 'Notifications for incoming SMS messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> showIncomingSmsNotification({
    required String address,
    required String body,
    int? notificationId,
  }) async {
    if (!_isInitialized) await init();

    final id = notificationId ?? address.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'sms_channel',
      'SMS Messages',
      channelDescription: 'Notifications for incoming SMS messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      category: AndroidNotificationCategory.message,
      styleInformation: null, // Could add BigTextStyleInformation for longer messages
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Truncate body for notification
    final displayBody = body.length > 100 ? '${body.substring(0, 100)}...' : body;

    await _notifications.show(
      id,
      address, // Title is the sender's number
      displayBody,
      notificationDetails,
      payload: address, // Use address as payload to open thread
    );

    debugPrint('Notification shown for SMS from $address');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }
}
