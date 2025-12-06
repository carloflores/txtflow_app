import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  static Map<String, String> _contactCache = {};
  static bool _isLoaded = false;
  static bool _hasPermission = false;

  /// Request contacts permission
  static Future<bool> requestPermission() async {
    try {
      _hasPermission = await FlutterContacts.requestPermission(readonly: true);
      debugPrint('ContactService: Permission granted: $_hasPermission');
      return _hasPermission;
    } catch (e) {
      debugPrint('ContactService: Error requesting permission: $e');
      return false;
    }
  }

  /// Load all contacts into cache for fast lookups
  static Future<void> loadContacts() async {
    if (_isLoaded) return;
    
    try {
      if (!_hasPermission) {
        _hasPermission = await FlutterContacts.requestPermission(readonly: true);
      }
      
      if (!_hasPermission) {
        debugPrint('ContactService: No permission to read contacts');
        return;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      debugPrint('ContactService: Loading ${contacts.length} contacts');

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _normalizeNumber(phone.number);
          if (normalized.isNotEmpty) {
            _contactCache[normalized] = contact.displayName;
          }
        }
      }
      
      _isLoaded = true;
      debugPrint('ContactService: Cached ${_contactCache.length} phone numbers');
    } catch (e) {
      debugPrint('ContactService: Error loading contacts: $e');
    }
  }

  /// Get contact name for a phone number
  static String? getContactName(String phoneNumber) {
    final normalized = _normalizeNumber(phoneNumber);
    return _contactCache[normalized];
  }

  /// Get display name - returns contact name if found, otherwise the number
  static String getDisplayName(String phoneNumber) {
    return getContactName(phoneNumber) ?? phoneNumber;
  }

  /// Refresh the contact cache
  static Future<void> refreshContacts() async {
    _isLoaded = false;
    _contactCache.clear();
    await loadContacts();
  }

  /// Normalize phone number for comparison (Philippine format)
  static String _normalizeNumber(String number) {
    // Remove all non-digit characters
    String cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Philippine number formats:
    // - +639xxxxxxxxx -> 9xxxxxxxxx
    // - 639xxxxxxxxx -> 9xxxxxxxxx
    // - 09xxxxxxxxx -> 9xxxxxxxxx
    // - 9xxxxxxxxx -> 9xxxxxxxxx
    
    if (cleaned.startsWith('63') && cleaned.length >= 12) {
      cleaned = cleaned.substring(2); // Remove 63
    } else if (cleaned.startsWith('0') && cleaned.length >= 11) {
      cleaned = cleaned.substring(1); // Remove leading 0
    }
    
    return cleaned;
  }

  /// Check if contacts permission is granted
  static bool get hasPermission => _hasPermission;
  
  /// Check if contacts are loaded
  static bool get isLoaded => _isLoaded;
}
