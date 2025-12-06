import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'TxtFlow SMS Gateway';
  
  // Storage Keys
  static const String keyApiUrl = 'api_url';
  static const String keyWhitelist = 'whitelist';
  static const String keyPollingInterval = 'polling_interval';
  static const String keyCustomHeaders = 'custom_headers';
  
  // Default Values
  static const String defaultApiUrl = 'https://yo.hellotap.app';
  static const int defaultPollingInterval = 5; // seconds
  
  // UI Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF00E676);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFCF6679);
}
