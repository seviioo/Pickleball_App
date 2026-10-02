import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import 'equipment_screen.dart';
import 'match_setup_screen.dart';
import 'practice_tutorial_screen.dart';
import 'settings_screen.dart';
import 'tournament_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;

  const LobbyScreen({
    Key? key,
    required this.userName,
    required this.characterStyle,
  }) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _coins = 0;
  int _xp = 0;
  int _wins = 0;
  int _losses = 0;
  bool _canClaimDaily = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final coins = await StorageService.getCoins();
    final xp = await StorageService.getXp();
    final wins = await StorageService.getWins();
    final losses = await StorageService.getLosses();
    final canClaim = await StorageService.canClaimDailyStash();

    if (mounted) {
      setState(() {
        _coins = coins;
        _xp = xp;
        _wins = wins;
        _losses = losses;
        _canClaimDaily = canClaim;
      });
    }
  }

  Future<void> _claimDailyStash() async {
    await StorageService.claimDailyStash();
    await _loadUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CLAIMED 150 COINS & 100 XP!'),
          backgroundColor: Colors.amberAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        widget.userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            currentUserName: widget.userName,
                          ),
                        ),
                      );
                      _loadUserData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('COINS', '$_coins',
                        Icons.monetization_on, Colors.amberAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                        'STREET XP', '$_xp', Icons.bolt, Colors.cyanAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('RECORD', '$_wins W - $_losses L',
                        Icons.emoji_events, Colors.greenAccent),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Daily Stash Banner
              if (_canClaimDaily)
                GestureDetector(
                  onTap: _claimDailyStash,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.indigo,
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.card_giftcard,
                            color: Colors.white, size: 32),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAILY STASH READY!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Tap to claim 150 Coins & 100 XP',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              if (_canClaimDaily) const SizedBox(height: 20),

              // Main Menu Options
              _buildMenuCard(
                title: 'QUICK MATCH',
                subtitle: 'Jump into an instant court match against AI',
                icon: Icons.sports_tennis,
                color: Colors.amberAccent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchSetupScreen(
                        userName: widget.userName,
                        characterStyle: widget.characterStyle,
                      ),
                    ),
                  );
                  _loadUserData();
                },
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                title: 'UNDERGROUND TOURNAMENT',
                subtitle: 'Climb the bracket to win the Grand Prize Purse',
                icon: Icons.emoji_events,
                color: Colors.orangeAccent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TournamentScreen(),
                    ),
                  );
                  _loadUserData();
                },
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                title: 'BLACK MARKET GEAR',
                subtitle: 'Unlock & equip high performance paddles',
                icon: Icons.shopping_bag,
                color: Colors.purpleAccent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EquipmentScreen(),
                    ),
                  );
                  _loadUserData();
                },
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                title: 'PRACTICE & TUTORIAL',
                subtitle: 'Master dinks, drives, and kitchen rules',
                icon: Icons.school,
                color: Colors.cyanAccent,
                onTap: () async {
                  final paddle = await StorageService.getEquippedPaddle();
                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PracticeTutorialScreen(
                        userName: widget.userName,
                        paddle: paddle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // SafeArea
    ); // Scaffold
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F232C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F232C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
