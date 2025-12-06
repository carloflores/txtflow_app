import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SimCard {
  final int subscriptionId;
  final int simSlotIndex;
  final String carrierName;
  final String displayName;
  final String phoneNumber;
  final String iccId;
  final String countryIso;

  SimCard({
    required this.subscriptionId,
    required this.simSlotIndex,
    required this.carrierName,
    required this.displayName,
    required this.phoneNumber,
    required this.iccId,
    required this.countryIso,
  });

  factory SimCard.fromMap(Map<dynamic, dynamic> map) {
    return SimCard(
      subscriptionId: map['subscriptionId'] as int? ?? -1,
      simSlotIndex: map['simSlotIndex'] as int? ?? 0,
      carrierName: map['carrierName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      iccId: map['iccId'] as String? ?? '',
      countryIso: map['countryIso'] as String? ?? '',
    );
  }

  String get label => displayName.isNotEmpty ? displayName : carrierName;
  
  String get slotLabel => 'SIM ${simSlotIndex + 1}';

  @override
  String toString() => 'SimCard($slotLabel: $label)';
}

class SimService {
  static const _channel = MethodChannel('com.carlodflores.txtflow/settings');

  /// Get list of available SIM cards
  static Future<List<SimCard>> getSimCards() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getSimCards');
      if (result == null) return [];
      
      return result
          .map((e) => SimCard.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SimService: Error getting SIM cards: $e');
      return [];
    }
  }

  /// Get default SIM subscription ID
  static Future<int> getDefaultSimSubscriptionId() async {
    try {
      final int? result = await _channel.invokeMethod('getDefaultSimSubscriptionId');
      return result ?? -1;
    } catch (e) {
      debugPrint('SimService: Error getting default SIM: $e');
      return -1;
    }
  }

  /// Send SMS using a specific SIM card
  static Future<bool> sendSmsWithSim({
    required String to,
    required String message,
    required int subscriptionId,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendSmsWithSim', {
        'to': to,
        'message': message,
        'subscriptionId': subscriptionId,
      });
      return result == true;
    } catch (e) {
      debugPrint('SimService: Error sending SMS: $e');
      rethrow;
    }
  }
}
