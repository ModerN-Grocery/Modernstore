import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SupportConfig {
  final String email;
  final String whatsapp;
  final String callNumber;

  const SupportConfig({
    required this.email,
    required this.whatsapp,
    required this.callNumber,
  });
}

class SupportConfigService {
  static const String _rtdbUrl =
      'https://moderern-store-default-rtdb.firebaseio.com/0/0.json';
  static const String _fallbackRtdbUrl =
      'https://moderern-store-default-rtdb.firebaseio.com/.json';

  static SupportConfig _cached = const SupportConfig(
    email: 'modernstoreputhupparamba@gmail.com',
    whatsapp: '+91 8139089227',
    callNumber: '+91 8139089227',
  );

  static SupportConfig get currentConfig => _cached;

  /// Fetches support configuration from Firebase Realtime Database.
  /// Falls back to cached values if network or database fails.
  static Future<SupportConfig> fetchSupportConfig() async {
    try {
      final response = await http
          .get(Uri.parse(_rtdbUrl))
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200 &&
          response.body.isNotEmpty &&
          response.body != 'null') {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final email = data['SUPPORT_MAIL']?.toString().trim() ??
              data['support_mail']?.toString().trim() ??
              data['email']?.toString().trim() ??
              _cached.email;

          final whatsapp = data['WHATSAPP_NUMBER']?.toString().trim() ??
              data['whatsapp_number']?.toString().trim() ??
              data['whatsapp']?.toString().trim() ??
              _cached.whatsapp;

          final call = data['CALL_NUMBER']?.toString().trim() ??
              data['PHONE_NUMBER']?.toString().trim() ??
              data['call_number']?.toString().trim() ??
              data['phone_number']?.toString().trim() ??
              whatsapp;

          _cached = SupportConfig(
            email: email.isNotEmpty ? email : _cached.email,
            whatsapp: whatsapp.isNotEmpty ? whatsapp : _cached.whatsapp,
            callNumber: call.isNotEmpty ? call : _cached.callNumber,
          );
          return _cached;
        }
      }

      // Fallback check on root
      final rootResponse = await http
          .get(Uri.parse(_fallbackRtdbUrl))
          .timeout(const Duration(seconds: 5));

      if (rootResponse.statusCode == 200 &&
          rootResponse.body.isNotEmpty &&
          rootResponse.body != 'null') {
        final rootData = jsonDecode(rootResponse.body);
        dynamic node;
        if (rootData is List && rootData.isNotEmpty) {
          final first = rootData[0];
          if (first is List && first.isNotEmpty) {
            node = first[0];
          } else if (first is Map) {
            node = first;
          }
        } else if (rootData is Map) {
          node = rootData['0']?['0'] ?? rootData;
        }

        if (node is Map) {
          final email = node['SUPPORT_MAIL']?.toString().trim() ?? _cached.email;
          final whatsapp =
              node['WHATSAPP_NUMBER']?.toString().trim() ?? _cached.whatsapp;
          final call = node['CALL_NUMBER']?.toString().trim() ??
              node['PHONE_NUMBER']?.toString().trim() ??
              whatsapp;

          _cached = SupportConfig(
            email: email.isNotEmpty ? email : _cached.email,
            whatsapp: whatsapp.isNotEmpty ? whatsapp : _cached.whatsapp,
            callNumber: call.isNotEmpty ? call : _cached.callNumber,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching support config from Firebase RTDB: $e');
    }
    return _cached;
  }
}
