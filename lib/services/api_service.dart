import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // --- AUTHENTICATION ---
  static Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
    required int age,
  }) async {
    try {
      final clientId = await StorageService.getOrCreateClientId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'clientId': clientId,
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
    String? Function(String message)? onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final clientId = result['clientId'];
        if (clientId is String) {
          await StorageService.saveClientId(clientId);
        }
        return result;
      }
      final message = _errorMessage(response);
      debugPrint('Login failed (${response.statusCode}): $message');
      onError?.call(message);
    } catch (e) {
      debugPrint('Login API Error: $e');
      onError?.call(
          'Unable to reach the online server. Check your internet connection.');
    }
    return null;
  }

  static Future<void> syncPlayer({required String displayName}) async {
    final clientId = await StorageService.getOrCreateClientId();
    final response = await http.put(
      Uri.parse('$baseUrl/api/players/$clientId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'displayName': displayName}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Player sync failed (${response.statusCode})');
    }
  }

  // --- ROOM MANAGEMENT ---
  static Future<Map<String, dynamic>?> createRoom(
      String roomCode, String hostUsername,
      {String? Function(String message)? onError}) async {
    try {
      final clientId = await StorageService.getOrCreateClientId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomCode': roomCode,
          'clientId': clientId,
          'mode': 'casual',
          'maxPlayers': 2,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final message = _errorMessage(response);
      debugPrint(
          'Create Room failed (${response.statusCode}): $message');
      onError?.call(message);
    } catch (e) {
      debugPrint('Create Room Error: $e');
      onError?.call('Unable to reach the online server. Check your internet connection.');
    }
    return null;
  }

  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) {
        return body['error'] as String;
      }
    } catch (_) {
      // Use the status code when the server did not return JSON.
    }
    return 'Server returned HTTP ${response.statusCode}.';
  }

  static Future<Map<String, dynamic>?> joinRoom(
      String roomCode, String guestUsername,
      {String? Function(String message)? onError}) async {
    try {
      final clientId = await StorageService.getOrCreateClientId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final message = _errorMessage(response);
      debugPrint('Join Room failed (${response.statusCode}): $message');
      onError?.call(message);
    } catch (e) {
      debugPrint('Join Room Error: $e');
      onError?.call(
          'Unable to reach the online server. Check your internet connection.');
    }
    return null;
  }

  static Future<bool> startRoomMatch(
      String roomCode, String hostUsername,
      {String? Function(String message)? onError}) async {
    try {
      final clientId = await StorageService.getOrCreateClientId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'clientId': clientId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      final message = _errorMessage(response);
      debugPrint('Start Room Match failed (${response.statusCode}): $message');
      onError?.call(message);
    } catch (e) {
      debugPrint('Start Room Match Error: $e');
      onError?.call(
          'Unable to reach the online server. Check your internet connection.');
      return false;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getRoomStatus(String roomCode) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/rooms/$roomCode'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
      } else {
        debugPrint(
            'Room status failed (${response.statusCode}): ${_errorMessage(response)}');
      }
    } catch (e) {
      debugPrint('Room status error: $e');
    }
    return null;
  }

  // --- LEADERBOARD ---
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/leaderboard'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final players = data is List ? data : (data['players'] ?? data['leaderboard'] ?? []);
        return players
            .map((player) => Map<String, dynamic>.from(player as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Leaderboard API Error: $e');
    }
    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> getMatchHistory() async {
    final clientId = await StorageService.getOrCreateClientId();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/players/$clientId/matches'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['matches'] as List<dynamic>)
            .map((match) => Map<String, dynamic>.from(match as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Match history API Error: $e');
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> submitMatch({
    required bool isVictory,
    required int playerScore,
    required int opponentScore,
    required String opponentName,
    required int coinsEarned,
    required int xpEarned,
    required int kitchenFaults,
    required int smashesLanded,
    required int longestRally,
    required bool isTournamentMatch,
    required int tournamentRound,
    required String idempotencyKey,
  }) async {
    final clientId = await StorageService.getOrCreateClientId();
    final response = await http.post(
      Uri.parse('$baseUrl/api/players/$clientId/matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idempotencyKey': idempotencyKey,
        'mode': 'solo',
        'isVictory': isVictory,
        'playerScore': playerScore,
        'opponentScore': opponentScore,
        'opponentName': opponentName,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
        'kitchenFaults': kitchenFaults,
        'smashesLanded': smashesLanded,
        'longestRally': longestRally,
        'isTournamentMatch': isTournamentMatch,
        'tournamentRound': tournamentRound,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Match submission failed (${response.statusCode})');
    }
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
      final clientId = await StorageService.getOrCreateClientId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/players/$clientId/matches'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchId': matchId,
          'roomCode': roomCode,
          'playerScore': playerScore,
          'opponentScore': opponentScore,
          'isVictory': isWinner,
          'mode': 'online',
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
