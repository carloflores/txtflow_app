import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/sms_message.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> reload() async {
    await _prefs.reload();
  }

  String get apiUrl => _prefs.getString(AppConstants.keyApiUrl) ?? AppConstants.defaultApiUrl;
  
  Future<void> setApiUrl(String url) async {
    await _prefs.setString(AppConstants.keyApiUrl, url);
  }

  List<String> get whitelist {
    final String? listString = _prefs.getString(AppConstants.keyWhitelist);
    if (listString == null || listString.isEmpty) {
      return [];
    }
    return listString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> setWhitelist(List<String> numbers) async {
    await _prefs.setString(AppConstants.keyWhitelist, numbers.join(','));
  }

  int get pollingInterval => _prefs.getInt(AppConstants.keyPollingInterval) ?? AppConstants.defaultPollingInterval;

  Future<void> setPollingInterval(int seconds) async {
    await _prefs.setInt(AppConstants.keyPollingInterval, seconds);
  }

  Map<String, String> get customHeaders {
    final String? jsonString = _prefs.getString(AppConstants.keyCustomHeaders);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  Future<void> setCustomHeaders(Map<String, String> headers) async {
    await _prefs.setString(AppConstants.keyCustomHeaders, jsonEncode(headers));
  }

  String get deviceId {
    String? id = _prefs.getString(AppConstants.keyDeviceId);
    if (id == null || id.isEmpty) {
      // Generate a unique device ID
      id = _generateDeviceId();
      _prefs.setString(AppConstants.keyDeviceId, id);
    }
    return id;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<String> get logs => _prefs.getStringList('app_logs') ?? [];

  Future<void> addLog(String log) async {
    final currentLogs = logs;
    final timestamp = DateTime.now().toString().split('.')[0];
    currentLogs.insert(0, '$timestamp - $log');
    if (currentLogs.length > 100) currentLogs.removeLast();
    await _prefs.setStringList('app_logs', currentLogs);
  }

  String get lastRecipient => _prefs.getString('last_recipient') ?? 'None';

  Future<void> setLastRecipient(String number) async {
    await _prefs.setString('last_recipient', number);
  }

  int get messagesSentCount => _prefs.getInt('messages_sent_count') ?? 0;

  Future<void> incrementSentCount() async {
    final current = messagesSentCount;
    await _prefs.setInt('messages_sent_count', current + 1);
  }

  int get messagesReceivedCount => _prefs.getInt('messages_received_count') ?? 0;

  Future<void> incrementReceivedCount() async {
    final current = messagesReceivedCount;
    await _prefs.setInt('messages_received_count', current + 1);
  }

  int get lastPollTime => _prefs.getInt('last_poll_time') ?? 0;

  Future<void> setLastPollTime(int timestamp) async {
    await _prefs.setInt('last_poll_time', timestamp);
  }

  // Deduplication logic
  List<String> get processedMessageIds => _prefs.getStringList('processed_message_ids') ?? [];

  Future<bool> isMessageProcessed(String id) async {
    final ids = processedMessageIds;
    return ids.contains(id);
  }

  Future<void> markMessageProcessed(String id) async {
    final ids = processedMessageIds;
    if (!ids.contains(id)) {
      ids.insert(0, id);
      if (ids.length > 50) ids.removeLast(); // Keep last 50 IDs
      await _prefs.setStringList('processed_message_ids', ids);
    }
  }

  // Auto-start service setting
  bool get autoStartService => _prefs.getBool(AppConstants.keyAutoStart) ?? true;

  Future<void> setAutoStartService(bool value) async {
    await _prefs.setBool(AppConstants.keyAutoStart, value);
  }

  // Notifications enabled setting
  bool get notificationsEnabled => _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(AppConstants.keyNotificationsEnabled, value);
  }

  // Selected SIM card for sending SMS (-1 = use default)
  int get selectedSimId => _prefs.getInt(AppConstants.keySelectedSimId) ?? -1;

  Future<void> setSelectedSimId(int subscriptionId) async {
    await _prefs.setInt(AppConstants.keySelectedSimId, subscriptionId);
  }

  // SMS Message Storage
  static const String _messagesKey = 'sms_messages';
  static const int _maxMessages = 500; // Limit stored messages

  List<LocalSmsMessage> get messages {
    final String? jsonString = _prefs.getString(_messagesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => LocalSmsMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMessage(LocalSmsMessage message) async {
    final currentMessages = messages;
    
    // Check for duplicate
    if (currentMessages.any((m) => m.id == message.id)) {
      return;
    }
    
    currentMessages.insert(0, message);
    
    // Trim to max messages
    while (currentMessages.length > _maxMessages) {
      currentMessages.removeLast();
    }
    
    await _prefs.setString(
      _messagesKey,
      jsonEncode(currentMessages.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> saveMessages(List<LocalSmsMessage> newMessages) async {
    for (final msg in newMessages) {
      await saveMessage(msg);
    }
  }

  List<LocalSmsMessage> getMessagesForContact(String address) {
    return messages.where((m) => _normalizeNumber(m.address) == _normalizeNumber(address)).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  List<Conversation> getConversations() {
    final allMessages = messages;
    final Map<String, List<LocalSmsMessage>> grouped = {};

    for (final msg in allMessages) {
      final normalized = _normalizeNumber(msg.address);
      grouped.putIfAbsent(normalized, () => []);
      grouped[normalized]!.add(msg);
    }

    final conversations = <Conversation>[];
    for (final entry in grouped.entries) {
      final msgs = entry.value..sort((a, b) => b.date.compareTo(a.date));
      final unread = msgs.where((m) => m.isIncoming && !m.isRead).length;
      
      conversations.add(Conversation(
        address: msgs.first.address, // Use original format from latest message
        lastMessage: msgs.first,
        unreadCount: unread,
        messageCount: msgs.length,
      ));
    }

    // Sort by last message date
    conversations.sort((a, b) => b.lastMessage.date.compareTo(a.lastMessage.date));
    return conversations;
  }

  Future<void> markConversationAsRead(String address) async {
    final allMessages = messages;
    final normalized = _normalizeNumber(address);
    bool changed = false;

    for (int i = 0; i < allMessages.length; i++) {
      if (_normalizeNumber(allMessages[i].address) == normalized && 
          allMessages[i].isIncoming && 
          !allMessages[i].isRead) {
        allMessages[i] = allMessages[i].copyWith(isRead: true);
        changed = true;
      }
    }

    if (changed) {
      await _prefs.setString(
        _messagesKey,
        jsonEncode(allMessages.map((m) => m.toJson()).toList()),
      );
    }
  }

  String _normalizeNumber(String number) {
    // Remove all non-digit characters except +
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle Philippine number formats:
    // - +639xxxxxxxxx -> 9xxxxxxxxx
    // - 639xxxxxxxxx -> 9xxxxxxxxx
    // - 09xxxxxxxxx -> 9xxxxxxxxx
    // - 9xxxxxxxxx -> 9xxxxxxxxx
    
    if (cleaned.startsWith('+63')) {
      cleaned = cleaned.substring(3); // Remove +63
    } else if (cleaned.startsWith('63') && cleaned.length >= 12) {
      cleaned = cleaned.substring(2); // Remove 63
    } else if (cleaned.startsWith('0') && cleaned.length >= 11) {
      cleaned = cleaned.substring(1); // Remove leading 0
    }
    
    return cleaned;
  }
}
