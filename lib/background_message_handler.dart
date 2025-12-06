import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'models/sms_message.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  final storage = StorageService();
  await storage.init();

  // Deduplication check
  final date = message.date ?? DateTime.now().millisecondsSinceEpoch;
  final messageId = '${message.address}_${date}_${message.body.hashCode}';
  if (await storage.isMessageProcessed(messageId)) {
    return;
  }
  await storage.markMessageProcessed(messageId);

  // Save to local storage for thread view
  final smsMessage = LocalSmsMessage(
    id: messageId,
    address: message.address ?? 'Unknown',
    body: message.body ?? '',
    date: date,
    isIncoming: true,
    isRead: false,
  );
  await storage.saveMessage(smsMessage);

  // Show notification if enabled
  if (storage.notificationsEnabled) {
    await _showBackgroundNotification(
      address: message.address ?? 'Unknown',
      body: message.body ?? '',
    );
  }

  final api = ApiService(storage);

  final log = 'Background: Received SMS from ${message.address}: ${message.body}';
  await storage.addLog(log);

  // Post to API
  await api.postMessage({
    'address': message.address,
    'body': message.body,
    'date': date,
  });

  await storage.incrementReceivedCount();
}

Future<void> _showBackgroundNotification({
  required String address,
  required String body,
}) async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'sms_channel',
    'SMS Messages',
    channelDescription: 'Notifications for incoming SMS messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    category: AndroidNotificationCategory.message,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  final displayBody = body.length > 100 ? '${body.substring(0, 100)}...' : body;

  await notifications.show(
    address.hashCode,
    address,
    displayBody,
    notificationDetails,
    payload: address,
  );
}
