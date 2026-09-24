import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'equipment_screen.dart';
import 'match_setup_screen.dart';
import 'practice_tutorial_screen.dart';
import 'tournament_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;

  const LobbyScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  int userCoins = 0;
  int userXp = 0;
  int userWins = 0;
  int userLosses = 0;
  bool canClaimStash = false;
  PaddleData equippedPaddle = PaddleData.starter();
  bool isSoundOn = true;
  bool isHapticsOn = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.98, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final coins = await StorageService.getCoins();
    final xp = await StorageService.getXp();
    final wins = await StorageService.getWins();
    final losses = await StorageService.getLosses();
    final canClaim = await StorageService.canClaimDailyStash();
    final paddle = await StorageService.getEquippedPaddle();
    final sound = await StorageService.getSoundEnabled();
    final haptics = await StorageService.getHapticsEnabled();

    if (mounted) {
      setState(() {
        userCoins = coins;
        userXp = xp;
        userWins = wins;
        userLosses = losses;
        canClaimStash = canClaim;
        equippedPaddle = paddle;
        isSoundOn = sound;
        isHapticsOn = haptics;
      });
    }
  }

  int get level => (userXp / 300).floor() + 1;
  double get levelProgress => ((userXp % 300) / 300.0).clamp(0.0, 1.0);

  String get rankTitle {
    if (level == 1) return 'Rookie Dinker';
    if (level == 2) return 'Alley Hustler';
    if (level == 3) return 'Kitchen Crusher';
    if (level == 4) return 'Baseline Boss';
    return 'Street Legend';
  }

  int get totalMatches => userWins + userLosses;
  String get winRate => totalMatches == 0
      ? '0%'
      : '${((userWins / totalMatches) * 100).toStringAsFixed(0)}%';

  void _claimDailyStash() async {
    await StorageService.claimDailyStash();
    await _loadData();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.gold, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldButton,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Colors.black, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DAILY STASH CLAIMED!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+150 COINS  ·  +100 XP',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('BOOST UP!',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.hairline, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings, color: AppColors.gold, size: 24),
                        SizedBox(width: 10),
                        Text('SETTINGS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      activeColor: AppColors.gold,
                      title: const Text('Sound FX',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      value: isSoundOn,
                      onChanged: (val) async {
                        setModalState(() => isSoundOn = val);
                        setState(() => isSoundOn = val);
                        AudioService.updateSettings(val, isHapticsOn);
                      },
                    ),
                    SwitchListTile(
                      activeColor: AppColors.gold,
                      title: const Text('Haptic Vibration',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      value: isHapticsOn,
                      onChanged: (val) async {
                        setModalState(() => isHapticsOn = val);
                        setState(() => isHapticsOn = val);
                        AudioService.updateSettings(isSoundOn, val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CLOSE',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreetBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.gold, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          widget.characterStyle.outfitPrimary,
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Kicker('LEVEL $level  ·  $rankTitle',
                                          color: AppColors.gold),
                                      Text(widget.userName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.hairline,
                                          width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.monetization_on,
                                            color: AppColors.gold, size: 18),
                                        const SizedBox(width: 6),
                                        Text('$userCoins',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.hairline,
                                          width: 1.5),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.settings,
                                          color: Colors.white, size: 20),
                                      onPressed: _openSettingsDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // XP Level Progress Bar
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.hairline, width: 1),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: levelProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldButton,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Daily Stash Bonus Banner
                          StreetCard(
                            borderColor: canClaimStash
                                ? AppColors.gold
                                : AppColors.hairline,
                            borderWidth: canClaimStash ? 1.6 : 1.2,
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: canClaimStash
                                        ? AppColors.gold.withOpacity(0.2)
                                        : AppColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.card_giftcard_rounded,
                                    color: canClaimStash
                                        ? AppColors.gold
                                        : AppColors.textFaint,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Kicker('DAILY STREET STASH'),
                                      Text(
                                        canClaimStash
                                            ? 'Bonus Ready: +150 Coins'
                                            : 'Claimed Today (24h Refresh)',
                                        style: TextStyle(
                                          color: canClaimStash
                                              ? AppColors.gold
                                              : AppColors.textSecondary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canClaimStash)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _claimDailyStash,
                                    child: const Text('CLAIM',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12)),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Lifetime Stats Widget
                          StreetCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn('WINS', '$userWins',
                                    color: AppColors.win),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.hairline),
                                _buildStatColumn('LOSSES', '$userLosses',
                                    color: AppColors.redBright),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColors.hairline),
                                _buildStatColumn('WIN RATE', winRate,
                                    color: AppColors.gold),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Equipped Paddle Card
                          StreetCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.red, width: 1.5),
                                  ),
                                  child: const Icon(Icons.sports_tennis,
                                      color: AppColors.gold, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Kicker('EQUIPPED PADDLE'),
                                      Text(equippedPaddle.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right,
                                      color: AppColors.gold),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EquipmentScreen(
                                          userName: widget.userName,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Animated Pulsing Quick Match CTA
                          AnimatedBuilder(
                            animation: _pulseScale,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseScale.value,
                                child: child,
                              );
                            },
                            child: PrimaryCTA(
                              label: 'QUICK STREET MATCH',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MatchSetupScreen(
                                      userName: widget.userName,
                                      paddle: equippedPaddle,
                                      characterStyle: widget.characterStyle,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: 'TOURNAMENT',
                                  icon: Icons.emoji_events,
                                  accent: AppColors.redBright,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TournamentScreen(
                                          userName: widget.userName,
                                          paddle: equippedPaddle,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SecondaryButton(
                                  label: 'BLACK MARKET',
                                  icon: Icons.shopping_bag,
                                  accent: AppColors.gold,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EquipmentScreen(
                                          userName: widget.userName,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PracticeTutorialScreen(
                                      userName: widget.userName,
                                      paddle: equippedPaddle,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.school, size: 18),
                              label: const Text('PRACTICE COURT & DRILLS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {required Color color}) {
    return Column(
      children: [
        Kicker(label, color: AppColors.textFaint),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
