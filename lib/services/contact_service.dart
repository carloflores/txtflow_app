import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactService {
  static Map<String, String> _contactCache = {};
  static bool _isLoaded = false;
  static bool _hasPermission = false;

  /// Request contacts permission (with write access)
  static Future<bool> requestPermission({bool readonly = false}) async {
    try {
      _hasPermission = await FlutterContacts.requestPermission(readonly: readonly);
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

  /// Save a new contact
  static Future<bool> saveContact(String name, String phoneNumber) async {
    try {
      // Request write permission
      final hasWritePermission = await FlutterContacts.requestPermission(readonly: false);
      if (!hasWritePermission) {
        debugPrint('ContactService: No write permission for contacts');
        return false;
      }

      final contact = Contact()
        ..name.first = name
        ..phones = [Phone(phoneNumber)];
      
      await contact.insert();
      debugPrint('ContactService: Saved new contact: $name');
      
      // Refresh cache to include new contact
      await refreshContacts();
      return true;
    } catch (e) {
      debugPrint('ContactService: Error saving contact: $e');
      return false;
    }
  }

  /// Open native contact app to create a new contact with number pre-filled
  static Future<void> openAddContact(String phoneNumber, {String? name}) async {
    try {
      final contact = Contact()
        ..phones = [Phone(phoneNumber)];
      
      if (name != null && name.isNotEmpty) {
        contact.name.first = name;
      }
      
      await FlutterContacts.openExternalInsert(contact);
    } catch (e) {
      debugPrint('ContactService: Error opening add contact: $e');
    }
  }

  /// Open native contact app to add phone to existing contact
  static Future<void> addToExistingContact(String phoneNumber) async {
    try {
      await FlutterContacts.openExternalInsert(Contact()..phones = [Phone(phoneNumber)]);
    } catch (e) {
      debugPrint('ContactService: Error opening add to contact: $e');
    }
  }

  /// Open contact in native contacts app
  static Future<void> openContact(String phoneNumber) async {
    try {
      final normalized = _normalizeNumber(phoneNumber);
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          if (_normalizeNumber(phone.number) == normalized) {
            await FlutterContacts.openExternalView(contact.id);
            return;
          }
        }
      }
      
      // If contact not found, open to create new
      await addToExistingContact(phoneNumber);
    } catch (e) {
      debugPrint('ContactService: Error opening contact: $e');
    }
  }

  /// Open phone dialer
  static Future<void> callNumber(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('ContactService: Error opening dialer: $e');
    }
  }

  /// Get all contacts for picker
  static Future<List<Contact>> getAllContacts() async {
    try {
      if (!_hasPermission) {
        _hasPermission = await FlutterContacts.requestPermission(readonly: true);
      }
      
      if (!_hasPermission) return [];
      
      return await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
    } catch (e) {
      debugPrint('ContactService: Error getting all contacts: $e');
      return [];
    }
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

  /// Check if a phone number is saved as a contact
  static bool isContact(String phoneNumber) {
    return getContactName(phoneNumber) != null;
  }
}

