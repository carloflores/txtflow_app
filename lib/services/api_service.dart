import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage;

  ApiService(this._storage);

  String get _baseUrl => _storage.apiUrl;

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': _storage.deviceId,
      ..._storage.customHeaders,
    };
  }

  Future<bool> checkHealth() async {
    try {
      // await _storage.addLog('API: Checking health...'); // Too verbose for frequent checks? Maybe keep it.
      final response = await http.get(
        Uri.parse('$_baseUrl/health-check'),
        headers: _headers,
      );
      debugPrint('Health Checking: ${response.statusCode}');
      if (response.statusCode != 200) {
        await _storage.addLog('API: Health check failed (Status: ${response.statusCode})');
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      await _storage.addLog('API: Health check error: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchMessages() async {
    try {
      await _storage.addLog('API: Fetching messages...');
      final response = await http.get(
        Uri.parse('$_baseUrl/messages'),
        headers: _headers,
      );
      debugPrint('Fetch messages status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        await _storage.addLog('API: Fetched ${messages.length} messages');
        return messages;
      } else {
        await _storage.addLog('API: Fetch failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Fetch messages failed: $e');
      await _storage.addLog('API: Fetch error: $e');
    }
    return [];
  }

  Future<bool> postMessage(Map<String, dynamic> messageData) async {
    try {
      await _storage.addLog('API: Posting message to server...');
      final response = await http.post(
        Uri.parse('$_baseUrl/message'),
        headers: _headers,
        body: jsonEncode(messageData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.addLog('API: Message posted successfully');
        return true;
      } else {
        await _storage.addLog('API: Post failed (Status: ${response.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('Post message failed: $e');
      await _storage.addLog('API: Post error: $e');
      return false;
    }
  }

  Future<bool> updateMessage(Map<String, dynamic> messageData) async {
    try {
      await _storage.addLog('API: Posting message to server...');
      final response = await http.patch(
        Uri.parse('$_baseUrl/message'),
        headers: _headers,
        body: jsonEncode(messageData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.addLog('API: Message posted successfully');
        return true;
      } else {
        await _storage.addLog('API: Post failed (Status: ${response.statusCode})');
        return false;
      }
    } catch (e) {
      debugPrint('Post message failed: $e');
      await _storage.addLog('API: Post error: $e');
      return false;
    }
  }

  Future<void> triggerCronClean() async {
    try {
      await _storage.addLog('API: Triggering cron clean...');
      final response = await http.post(
        Uri.parse('$_baseUrl/cron/clean'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        await _storage.addLog('API: Cron clean triggered');
      } else {
        await _storage.addLog('API: Cron clean failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Cron clean failed: $e');
      await _storage.addLog('API: Cron clean error: $e');
    }
  }
}

