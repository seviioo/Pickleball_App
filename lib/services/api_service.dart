import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your groupmate's server URL:
  // - Localhost testing on Android Emulator: 'http://10.0.2.2:3000'
  // - Localhost testing on Web/Desktop: 'http://localhost:3000'
  // - Real Phone on same Wi-Fi: 'http://192.168.x.x:3000'
  static String baseUrl = 'http://localhost:3000';

  // --- AUTHENTICATION ---
  static Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
    required int age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'age': age,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Register API Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Login API Error: $e');
    }
    return null;
  }

  // --- ROOM MANAGEMENT ---
  static Future<Map<String, dynamic>?> createRoom(
      String roomCode, String hostUsername) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomCode': roomCode,
          'hostUsername': hostUsername,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Create Room Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> joinRoom(
      String roomCode, String guestUsername) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guestUsername': guestUsername,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Join Room Error: $e');
    }
    return null;
  }

  static Future<bool> startRoomMatch(
      String roomCode, String hostUsername) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hostUsername': hostUsername}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Start Room Match Error: $e');
      return false;
    }
  }

  // --- LEADERBOARD ---
  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/leaderboard'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['leaderboard'] ?? []);
      }
    } catch (e) {
      debugPrint('Leaderboard API Error: $e');
    }
    return [];
  }

  // --- MATCH RESULT SUBMISSION ---
  static Future<bool> submitMatchResult({
    required String username,
    required String matchId,
    required String roomCode,
    required int playerScore,
    required int opponentScore,
    required bool isWinner,
    required String idempotencyKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/players/$username/matches'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchId': matchId,
          'roomCode': roomCode,
          'playerScore': playerScore,
          'opponentScore': opponentScore,
          'isWinner': isWinner,
          'idempotencyKey': idempotencyKey,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Submit Match Result Error: $e');
      return false;
    }
  }
}
