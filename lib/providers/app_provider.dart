import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:telephony/telephony.dart' hide NetworkType;
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/sim_service.dart';
import '../services/contact_service.dart';
import '../models/sms_message.dart';
import '../background_message_handler.dart';

class AppProvider extends ChangeNotifier {
  final StorageService storage;
  late ApiService api;
  final NotificationService _notificationService = NotificationService();
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

  // SIM card management
  List<SimCard> _simCards = [];
  List<SimCard> get simCards => _simCards;
  
  int get selectedSimId => storage.selectedSimId;
  
  SimCard? get selectedSim {
    if (_simCards.isEmpty) return null;
    if (selectedSimId == -1) return _simCards.first; // Default to first SIM
    return _simCards.firstWhere(
      (s) => s.subscriptionId == selectedSimId,
      orElse: () => _simCards.first,
    );
  }

  AppProvider(this.storage) {
    api = ApiService(storage);
    _init();
  }

  Future<void> _init() async {
    await _notificationService.init();
    await _notificationService.requestPermission();
    
    checkHealth();
    loadLogs();
    _fetchSystemPhoneNumber();
    _startLogRefresh();
    await loadSimCards(); // Load available SIM cards
    await _loadContacts(); // Load device contacts for name lookups
    await _initTelephony();
    
    // Auto-start service if enabled
    if (storage.autoStartService && !_isServiceRunning) {
      _autoStartService();
    }
  }

  Future<void> _loadContacts() async {
    try {
      await ContactService.requestPermission();
      await ContactService.loadContacts();
      addLog('Contacts loaded: ${ContactService.isLoaded}');
    } catch (e) {
      debugPrint('AppProvider: Error loading contacts: $e');
    }
  }

  Future<void> loadSimCards() async {
    try {
      // Request phone permissions first (needed for SIM access)
      final telephony = Telephony.instance;
      final hasPermission = await telephony.requestPhonePermissions;
      debugPrint('AppProvider: Phone permission granted: $hasPermission');
      
      if (hasPermission != true) {
        debugPrint('AppProvider: Phone permission denied, cannot access SIM cards');
        addLog('Warning: Phone permission denied - SIM selection unavailable');
        return;
      }
      
      _simCards = await SimService.getSimCards();
      debugPrint('AppProvider: Loaded ${_simCards.length} SIM cards');
      
      if (_simCards.isEmpty) {
        debugPrint('AppProvider: No SIM cards returned from native code');
        addLog('Info: No SIM cards detected');
      } else {
        for (final sim in _simCards) {
          debugPrint('  - ${sim.slotLabel}: ${sim.label} (ID: ${sim.subscriptionId})');
        }
        addLog('Detected ${_simCards.length} SIM card(s)');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error loading SIM cards: $e');
      addLog('Error loading SIM cards: $e');
    }
  }

  Future<void> setSelectedSim(int subscriptionId) async {
    await storage.setSelectedSimId(subscriptionId);
    final sim = _simCards.firstWhere(
      (s) => s.subscriptionId == subscriptionId,
      orElse: () => _simCards.first,
    );
    addLog('Selected SIM: ${sim.slotLabel} - ${sim.label}');
    notifyListeners();
  }

  /// Send SMS using the selected SIM card
  Future<bool> sendSmsWithSelectedSim({
    required String to,
    required String message,
  }) async {
    final simId = selectedSimId;
    debugPrint('AppProvider: Sending SMS via SIM ID: $simId');
    
    try {
      await SimService.sendSmsWithSim(
        to: to,
        message: message,
        subscriptionId: simId,
      );
      return true;
    } catch (e) {
      debugPrint('AppProvider: SMS send error: $e');
      rethrow;
    }
  }

  void _autoStartService() {
    _isServiceRunning = true;
    addLog('Service auto-started');
    _registerBackgroundTask();
    _manageForegroundTimer();
    notifyListeners();
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
        await _handleIncomingSms(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
    addLog('listenIncomingSms setup complete');
  }

  Future<void> _handleIncomingSms(SmsMessage message) async {
    addLog('Foreground: Received SMS from ${message.address}');
    
    // Deduplication check
    final date = message.date ?? DateTime.now().millisecondsSinceEpoch;
    final messageId = '${message.address}_${date}_${message.body.hashCode}';
    
    if (await storage.isMessageProcessed(messageId)) {
      addLog('Message already processed: $messageId');
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
      await _notificationService.showIncomingSmsNotification(
        address: message.address ?? 'Unknown',
        body: message.body ?? '',
      );
    }

    // Post to API
    await api.postMessage({
      'address': message.address,
      'body': message.body,
      'date': date,
    });
    
    await storage.incrementReceivedCount();
    await loadLogs();
    notifyListeners();
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

  void startService() {
    if (!_isServiceRunning) {
      toggleService();
    }
  }

  void stopService() {
    if (_isServiceRunning) {
      toggleService();
    }
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
      
      for (final msg in messages) {
        final String address = msg['address'];
        final String body = msg['body'];
        final String id = msg['id'];
        
        // Save outgoing message to storage
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
          await sendSmsWithSelectedSim(to: address, message: body);
          await storage.setLastRecipient(address);
          await storage.incrementSentCount();
          addLog('Sent SMS to $address');
          
          // Report success
          await api.updateMessage({'id': id});
        } catch (e) {
          addLog('Failed to send to $address: $e');
        }
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

  Future<void> updateSettings(String url, List<String> whitelist, int interval, {Map<String, String>? customHeaders}) async {
    await storage.setApiUrl(url);
    await storage.setWhitelist(whitelist);
    await storage.setPollingInterval(interval);
    if (customHeaders != null) {
      await storage.setCustomHeaders(customHeaders);
    }
    await checkHealth();
    
    if (_isServiceRunning) {
      // Re-register to apply new interval
      await Workmanager().cancelAll();
      await _registerBackgroundTask();
    }
    
    notifyListeners();
  }

  // Settings helpers
  Future<void> setAutoStart(bool value) async {
    await storage.setAutoStartService(value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await storage.setNotificationsEnabled(value);
    notifyListeners();
  }
}
