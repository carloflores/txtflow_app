import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';

const String taskName = 'sms_gateway_polling';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final storage = StorageService();
      await storage.init();
      final api = ApiService(storage);
    
      // Update last poll time
      await storage.setLastPollTime(DateTime.now().millisecondsSinceEpoch);

      // The original code had `final telephony = Telephony.instance;` here.
      // The user's snippet suggests moving it into an `if` block, but the snippet itself is incomplete/syntactically incorrect.
      // To maintain syntactical correctness and incorporate the `if` block as much as possible,
      // I will assume the intent was to wrap the main logic for the specific task.
      // However, the `telephony` declaration needs to be handled correctly.
      // Given the instruction to make the change faithfully and syntactically correct,
      // I will place the `telephony` declaration where it was originally,
      // and add the `if` block around the subsequent logic if that was the intent.
      // But the snippet `if (task == 'sms_gateway_polling') {= Telephony.instance;` is not valid.
      // I will only apply the `setLastPollTime` and ensure the rest remains syntactically correct.
      // If the user intended to move `telephony` or add a new `try` block, they need to provide a syntactically valid snippet for that.

      final telephony = Telephony.instance;

      // 1. Check Health (Optional, just logging)
      await storage.addLog('Background: Checking server health...');
      final isOnline = await api.checkHealth();
      if (!isOnline) {
        final log = 'Background: Server offline';
        debugPrint(log);
        await storage.addLog(log);
        return Future.value(false);
      }
      await storage.addLog('Background: Server online');

      // 2. Fetch Messages and Send SMS
      await storage.addLog('Background: Polling for messages...');
      final messages = await api.fetchMessages();
      
      if (messages.isEmpty) {
        await storage.addLog('Background: No new messages to send');
      } else {
        await storage.addLog('Background: Found ${messages.length} messages');
        for (final msg in messages) {
          final String address = msg['address'];
          final String body = msg['body'];
          final String id = msg['id'];
          
          // Send SMS
          await telephony.sendSms(to: address, message: body);
          await storage.setLastRecipient(address);
          await storage.incrementSentCount();
          
          final log = 'Sent SMS to $address';
          debugPrint('Background task: $log');
          await storage.addLog(log);
          
          // Report success
          await api.updateMessage({'id': id});
        }
      }

      // 3. Trigger Cron Clean
      // await storage.addLog('Background: Triggering cleanup...');
      // await api.triggerCronClean();
      await storage.addLog('Background: Task completed');
      
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}
