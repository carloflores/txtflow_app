import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:telephony/telephony.dart' hide NetworkType;
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../background_message_handler.dart';

class AppProvider extends ChangeNotifier {
  final StorageService storage;
  late ApiService api;
  Timer? _logTimer;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  List<String> _logs = [];
  List<String> get logs => _logs;

  String _lastRecipient = 'None';
  String get lastRecipient => _lastRecipient;

  String _systemPhoneNumber = 'Unknown';
  String get systemPhoneNumber => _systemPhoneNumber;

  AppProvider(this.storage) {
    api = ApiService(storage);
    checkHealth();
    loadLogs();
    _fetchSystemPhoneNumber();
    _startLogRefresh();
    _initTelephony();
  }

  Future<void> _initTelephony() async {
    final telephony = Telephony.instance;
    
    // Check if SMS capable
    final bool? isCapable = await telephony.isSmsCapable;
    addLog('Is SMS Capable: $isCapable');

    final bool? result = await telephony.requestPhoneAndSmsPermissions;
    addLog('Permissions Request Result: $result');
    
    if (result != true) {
      addLog('Permissions not granted!');
      return;
    }

    addLog('Setting up listenIncomingSms...');
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        addLog('Foreground: Received SMS from ${message.address}');
        
        // Deduplication check
        final date = message.date ?? DateTime.now().millisecondsSinceEpoch;
        final messageId = '${message.address}_${date}_${message.body.hashCode}';
        
        if (await storage.isMessageProcessed(messageId)) {
          addLog('Message already processed: $messageId');
          return;
        }
        await storage.markMessageProcessed(messageId);

        // Post to API
        await api.postMessage({
          'address': message.address,
          'body': message.body,
          'date': date,
        });
        
        await storage.incrementReceivedCount();
        await loadLogs();
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
    addLog('listenIncomingSms setup complete');
  }



  void _startLogRefresh() {
    _logTimer = Timer.periodic(const Duration(seconds: 2), (_) => loadLogs());
  }

  Future<void> _fetchSystemPhoneNumber() async {
    try {
      const platform = MethodChannel('com.carlodflores.txtflow/settings');
      final String? number = await platform.invokeMethod('getSystemPhoneNumber');
      if (number != null && number.isNotEmpty) {
        _systemPhoneNumber = number;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to get system phone number: $e');
    }
  }

  void toggleService() {
    _isServiceRunning = !_isServiceRunning;
    addLog(_isServiceRunning ? 'Service started' : 'Service stopped');
    
    if (_isServiceRunning) {
      _registerBackgroundTask();
    } else {
      Workmanager().cancelAll();
    }
    
    _manageForegroundTimer();
    notifyListeners();
  }

  Future<void> _registerBackgroundTask() async {
    final interval = storage.pollingInterval; // in minutes
    await Workmanager().registerPeriodicTask(
      'sms_gateway_polling',
      'sms_gateway_polling',
      frequency: Duration(minutes: interval),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    addLog('Background task registered (Interval: $interval min)');
  }

  Future<void> checkHealth() async {
    _isOnline = await api.checkHealth();
    notifyListeners();
  }

  Future<void> loadLogs() async {
    await storage.reload();
    _logs = storage.logs;
    _lastRecipient = storage.lastRecipient;
    notifyListeners();
  }

  int get messagesSentCount => storage.messagesSentCount;
  int get messagesReceivedCount => storage.messagesReceivedCount;

  Timer? _foregroundTimer;
  bool _isInForeground = true;

  void setForegroundState(bool isForeground) {
    _isInForeground = isForeground;
    _manageForegroundTimer();
    notifyListeners();
  }

  void _manageForegroundTimer() {
    _foregroundTimer?.cancel();
    
    if (_isServiceRunning && _isInForeground) {
      // Run immediately
      _performPoll();
      // Then every 60 seconds
      _foregroundTimer = Timer.periodic(const Duration(seconds: 60), (_) => _performPoll());
    }
  }

  Future<void> _performPoll() async {
    addLog('Foreground: Polling messages...');
    final messages = await api.fetchMessages();
    
    if (messages.isNotEmpty) {
      addLog('Foreground: Found ${messages.length} messages');
      final telephony = Telephony.instance;
      
      for (final msg in messages) {
        final String address = msg['address'];
        final String body = msg['body'];
        final String id = msg['id'];
        
        // Send SMS
        await telephony.sendSms(to: address, message: body);
        await storage.setLastRecipient(address);
        await storage.incrementSentCount();
        
        addLog('Sent SMS to $address');
        
        // Report success
        await api.updateMessage({'id': id});
      }
    } else {
      addLog('Foreground: No new messages');
    }

    // Update last poll time
    await storage.setLastPollTime(DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    _foregroundTimer?.cancel();
    super.dispose();
  }

  DateTime? get nextPollTime {
    final last = storage.lastPollTime;
    if (last == 0) return null;
    
    // If in foreground, use 1 minute interval
    // If background, use stored interval
    final interval = _isInForeground ? 1 : storage.pollingInterval;
    return DateTime.fromMillisecondsSinceEpoch(last).add(Duration(minutes: interval));
  }

  Future<void> addLog(String log) async {
    await storage.addLog(log);
    await loadLogs();
  }

  Future<void> updateSettings(String url, List<String> whitelist, int interval) async {
    await storage.setApiUrl(url);
    await storage.setWhitelist(whitelist);
    await storage.setPollingInterval(interval);
    await checkHealth();
    
    if (_isServiceRunning) {
      // Re-register to apply new interval
      await Workmanager().cancelAll();
      await _registerBackgroundTask();
    }
    
    notifyListeners();
  }
}
