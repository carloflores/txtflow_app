import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

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
}
