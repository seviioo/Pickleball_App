import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class StorageService {
  static const String _keyCoins = 'user_coins';
  static const String _keyXp = 'user_xp';
  static const String _keyUserName = 'user_name';
  static const String _keyEquippedPaddle = 'equipped_paddle_id';
  static const String _keyUnlockedPaddles = 'unlocked_paddles';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keyWins = 'user_wins';
  static const String _keyLosses = 'user_losses';
  static const String _keyLastDailyClaim = 'last_daily_claim';

  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 100;
  }

  static Future<void> setCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, coins);
  }

  static Future<void> addCoins(int amount) async {
    final current = await getCoins();
    await setCoins(current + amount);
  }

  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  static Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getXp();
    await prefs.setInt(_keyXp, current + amount);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Player 1';
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  static Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHapticsEnabled) ?? true;
  }

  static Future<int> getWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWins) ?? 0;
  }

  static Future<int> getLosses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLosses) ?? 0;
  }

  static Future<void> recordMatchResult({required bool isWin}) async {
    final prefs = await SharedPreferences.getInstance();
    if (isWin) {
      final wins = prefs.getInt(_keyWins) ?? 0;
      await prefs.setInt(_keyWins, wins + 1);
    } else {
      final losses = prefs.getInt(_keyLosses) ?? 0;
      await prefs.setInt(_keyLosses, losses + 1);
    }
  }

  static Future<bool> canClaimDailyStash() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaim = prefs.getInt(_keyLastDailyClaim) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastClaim) >= 86400000; // 24 hours
  }

  static Future<void> claimDailyStash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _keyLastDailyClaim, DateTime.now().millisecondsSinceEpoch);
    await addCoins(150);
    await addXp(100);
  }

  static Future<List<PaddleData>> getPaddles() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds =
        prefs.getStringList(_keyUnlockedPaddles) ?? ['starter_wooden'];

    final allPaddles = [
      PaddleData(
        id: 'starter_wooden',
        name: 'Wooden Starter 10mm',
        power: 45,
        control: 60,
        spin: 40,
        price: 0,
        isUnlocked: true,
      ),
      PaddleData(
        id: 'composite_12mm',
        name: 'FiberFlex Composite 12mm',
        power: 65,
        control: 75,
        spin: 70,
        price: 250,
      ),
      PaddleData(
        id: 'pro_carbon_16mm',
        name: 'Pro Carbon Raw 16mm',
        power: 85,
        control: 80,
        spin: 90,
        price: 600,
      ),
    ];

    return allPaddles.map((paddle) {
      final isUnlocked =
          unlockedIds.contains(paddle.id) || paddle.id == 'starter_wooden';
      return PaddleData(
        id: paddle.id,
        name: paddle.name,
        power: paddle.power,
        control: paddle.control,
        spin: paddle.spin,
        price: paddle.price,
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  static Future<PaddleData> getEquippedPaddle() async {
    final prefs = await SharedPreferences.getInstance();
    final equippedId = prefs.getString(_keyEquippedPaddle) ?? 'starter_wooden';
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
        prefs.getStringList(_keyUnlockedPaddles) ?? ['starter_wooden'];
    if (!unlockedIds.contains(paddleId)) {
      unlockedIds.add(paddleId);
      await prefs.setStringList(_keyUnlockedPaddles, unlockedIds);
    }
  }
}
