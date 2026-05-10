import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';

/// API Client for AutoFix AI Simulator backend
class ApiClient {
  static const _baseUrl = 'https://kw9p0x0sz4.execute-api.us-east-1.amazonaws.com';

  Future<Map<String, String>> get _headers async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // === User ===

  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$_baseUrl/user/profile'), headers: await _headers);
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> claimLoginBonus() async {
    final res = await http.post(Uri.parse('$_baseUrl/user/login-bonus'), headers: await _headers);
    return _parseResponse(res);
  }

  // === Game ===

  Future<Map<String, dynamic>> startGame(int scenarioId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/game/start'),
      headers: await _headers,
      body: jsonEncode({'scenarioId': scenarioId}),
    );
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> sendMessage(String sessionId, String message, {String lang = 'tr'}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/game/message'),
      headers: await _headers,
      body: jsonEncode({'sessionId': sessionId, 'message': message, 'langCode': lang}),
    );
    return _parseResponse(res);
  }

  // === Hint ===

  Future<Map<String, dynamic>> requestHint(String sessionId, {String lang = 'tr'}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/hint'),
      headers: await _headers,
      body: jsonEncode({'sessionId': sessionId, 'lang': lang}),
    );
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> updateProfile(String displayName) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/user/profile'),
      headers: await _headers,
      body: jsonEncode({'displayName': displayName}),
    );
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> mergeProfile(String oldAnonymousId, Map<String, dynamic> localData) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/user/merge'),
      headers: await _headers,
      body: jsonEncode({
        'oldAnonymousId': oldAnonymousId,
        'localData': localData,
      }),
    );
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/user/profile'),
      headers: await _headers,
    );
    return _parseResponse(res);
  }

  // === Report ===

  Future<Map<String, dynamic>> reportMessage(String sessionId, String messageContent) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/report'),
      headers: await _headers,
      body: jsonEncode({
        'sessionId': sessionId,
        'messageContent': messageContent,
        'reason': 'Inappropriate AI behavior (Reported by User)'
      }),
    );
    return _parseResponse(res);
  }

  // === Ad Reward ===

  Future<Map<String, dynamic>> claimAdReward(String rewardType, {String? sessionId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ad/reward'),
      headers: await _headers,
      body: jsonEncode({
        'rewardType': rewardType,
        if (sessionId != null) 'sessionId': sessionId,
      }),
    );
    return _parseResponse(res);
  }

  // === Leaderboard ===

  Future<Map<String, dynamic>> getLeaderboard(String period) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/leaderboard/$period'),
      headers: await _headers,
    );
    return _parseResponse(res);
  }

  // === Helpers ===

  Map<String, dynamic> _parseResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
        statusCode: res.statusCode,
        error: body['error'] as String? ?? 'unknown',
        message: body['message'] as String? ?? 'Something went wrong',
      );
    }
    return body;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String error;
  final String message;

  ApiException({required this.statusCode, required this.error, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $error — $message';
}
