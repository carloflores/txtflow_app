import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/sim_service.dart';
import 'models/sms_message.dart';

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
        
        // Get selected SIM ID
        final selectedSimId = storage.selectedSimId;
        
        for (final msg in messages) {
          final String address = msg['address'];
          final String body = msg['body'];
          final String id = msg['id'];
          
          // Save outgoing message to storage for thread view
          final smsMessage = LocalSmsMessage(
            id: '${address}_${DateTime.now().millisecondsSinceEpoch}_out',
            address: address,
            body: body,
            date: DateTime.now().millisecondsSinceEpoch,
            isIncoming: false,
            status: 'sent',
          );
          await storage.saveMessage(smsMessage);
          
          // Send SMS using selected SIM
          try {
            await SimService.sendSmsWithSim(
              to: address,
              message: body,
              subscriptionId: selectedSimId,
            );
            
            await storage.setLastRecipient(address);
            await storage.incrementSentCount();
            
            final log = 'Sent SMS to $address';
            debugPrint('Background task: $log');
            await storage.addLog(log);
            
            // Report success
            await api.updateMessage({'id': id});
          } catch (e) {
            debugPrint('Background task: Failed to send to $address: $e');
            await storage.addLog('Failed to send to $address: $e');
          }
        }
      }

      await storage.addLog('Background: Task completed');
      
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}
