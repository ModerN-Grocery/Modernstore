import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:modern_grocery/repositery/api/api_client.dart';
import 'package:modern_grocery/repositery/model/login_model.dart';

class GetAllUsersApi {
  final ApiClient apiClient = ApiClient();

  /// Attempts to fetch all registered users from the backend.
  /// Checks standard endpoints: /user/all, /admin/users, /user/getAll, /user/get/all
  Future<List<User>?> getAllUsers() async {
    final candidateEndpoints = [
      '/user/all',
      '/admin/users',
      '/user/getAll',
      '/user/get/all',
      '/auth/users',
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final Response response =
            await apiClient.invokeAPI(endpoint, 'GET', null);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          List<dynamic>? userList;

          if (decoded is List) {
            userList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is List) {
              userList = decoded['data'];
            } else if (decoded['users'] is List) {
              userList = decoded['users'];
            } else if (decoded['result'] is List) {
              userList = decoded['result'];
            }
          }

          if (userList != null) {
            final users = userList
                .whereType<Map<String, dynamic>>()
                .map((json) => User.fromJson(json))
                .toList();

            if (kDebugMode) {
              print(' Successfully fetched ${users.length} users from $endpoint');
            }
            return users;
          }
        }
      } catch (e) {
        // Continue trying next candidate endpoint
      }
    }

    return null;
  }
}
