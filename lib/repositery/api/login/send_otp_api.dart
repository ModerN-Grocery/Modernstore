import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:modern_grocery/main.dart';
import 'package:modern_grocery/repositery/model/send_otp_model.dart';

class SendOtpApi {
  final String otpUrl = '$basePath/auth/send-otp';

  Future<SendOtpModel> sendOtp(String phoneNumber) async {
    final body = jsonEncode({
      "phoneNumber": phoneNumber,
    });

    if (kDebugMode) {
      print('🚀 Sending OTP Request to: $otpUrl');
      print('📦 Body: $body');
    }

    final response = await http
        .post(
          Uri.parse(otpUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw Exception(
          'Connection timeout: Backend server at $otpUrl is not responding.');
    });

    if (kDebugMode) {
      print('📡 Send OTP Response [${response.statusCode}]: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SendOtpModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to send OTP (${response.statusCode}): ${response.body}');
    }
  }
}
