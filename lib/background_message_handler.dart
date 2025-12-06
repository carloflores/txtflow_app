import 'package:telephony/telephony.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  final storage = StorageService();
  await storage.init();

  // Deduplication check
  final messageId = '${message.address}_${message.date}_${message.body.hashCode}';
  if (await storage.isMessageProcessed(messageId)) {
    return;
  }
  await storage.markMessageProcessed(messageId);

  final api = ApiService(storage);

  final log = 'Background: Received SMS from ${message.address}: ${message.body}';
  await storage.addLog(log);

  // Post to API
  await api.postMessage({
    'address': message.address,
    'body': message.body,
    'date': message.date,
  });
}
