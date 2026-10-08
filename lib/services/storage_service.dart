import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class StorageService {
  static const String _keyClientId = 'api_client_id';
  static const String _keyCoins = 'user_coins';
  static const String _keyXp = 'user_xp';
  static const String _keyWins = 'user_wins';
  static const String _keyLosses = 'user_losses';
  static const String _keyUserName = 'user_name';
  static const String _keyRegistered = 'account_registered';
  static const String _keyPasswordHash = 'account_password_hash';
  static const String _keyEquippedPaddle = 'equipped_paddle_id';
  static const String _keyUnlockedPaddles = 'unlocked_paddles';
  static const String _keyLastDailyClaim = 'last_daily_claim';
  static const String _keyTournamentRound = 'tournament_round';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyHapticsEnabled = 'haptics_enabled';

  static Future<String> getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_keyClientId);
    if (existingId != null && existingId.isNotEmpty) return existingId;

    final clientId =
        'device_${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_keyClientId, clientId);
    return clientId;
  }

  // Audio & Haptics Settings
  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  static Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHapticsEnabled) ?? true;
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHapticsEnabled, enabled);
  }

  // Coins Management
  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 500;
  }

  static Future<void> setCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, coins);
  }

  // XP Management
  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  static Future<void> setXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyXp, xp);
  }

  // Match Stats Management
  static Future<int> getWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWins) ?? 0;
  }

  static Future<void> setWins(int wins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWins, wins);
  }

  static Future<int> getLosses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLosses) ?? 0;
  }

  static Future<void> setLosses(int losses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLosses, losses);
  }

  // User Profile
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? '';
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<void> registerAccount({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, username);
    await prefs.setString(_keyPasswordHash, _hashPassword(password));
    await prefs.setBool(_keyRegistered, true);
  }

  static Future<bool> verifyCredentials({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getBool(_keyRegistered) ?? false;
    final savedUsername = prefs.getString(_keyUserName) ?? '';
    final savedPasswordHash = prefs.getString(_keyPasswordHash) ?? '';

    return registered &&
        savedUsername.toLowerCase() == username.toLowerCase() &&
        savedPasswordHash == _hashPassword(password);
  }

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Daily Stash Reward
  static Future<bool> canClaimDailyStash() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimMillis = prefs.getInt(_keyLastDailyClaim) ?? 0;
    final now = DateTime.now();
    final lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastClaimMillis);

    return now.difference(lastClaimDate).inHours >= 24;
  }

  static Future<void> claimDailyStash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _keyLastDailyClaim, DateTime.now().millisecondsSinceEpoch);
    final currentCoins = await getCoins();
    final currentXp = await getXp();
    await setCoins(currentCoins + 150);
    await setXp(currentXp + 100);
  }

  // Equipment & Black Market Inventory
  static Future<List<PaddleData>> getPaddles() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds =
        prefs.getStringList(_keyUnlockedPaddles) ?? ['starter_paddle'];

    return kDefaultPaddles.map((paddle) {
      final isUnlocked = unlockedIds.contains(paddle.id);
      return paddle.copyWith(isUnlocked: isUnlocked);
    }).toList();
  }

  static Future<PaddleData> getEquippedPaddle() async {
    final prefs = await SharedPreferences.getInstance();
    final equippedId = prefs.getString(_keyEquippedPaddle) ?? 'starter_paddle';
    final paddles = await getPaddles();
    return paddles.firstWhere(
      (p) => p.id == equippedId,
      orElse: () => PaddleData.starter(),
    );
  }

  static Future<void> setEquippedPaddle(PaddleData paddle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedPaddle, paddle.id);
  }

  static Future<void> unlockPaddle(String paddleId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds =
        prefs.getStringList(_keyUnlockedPaddles) ?? ['starter_paddle'];
    if (!unlockedIds.contains(paddleId)) {
      unlockedIds.add(paddleId);
      await prefs.setStringList(_keyUnlockedPaddles, unlockedIds);
    }
  }

  // Tournament Bracket Persistence
  static Future<int> getTournamentRound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTournamentRound) ?? 0;
  }

  static Future<void> setTournamentRound(int round) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTournamentRound, round);
  }

  static Future<void> resetTournament() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTournamentRound, 0);
  }
}
