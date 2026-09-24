import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSavedProfile();
  }

  Future<void> _checkSavedProfile() async {
    final savedName = await StorageService.getUserName();
    if (savedName.isNotEmpty) {
      _nameController.text = savedName;
    } else {
      _nameController.text = 'Player 1';
    }
  }

  void _proceedToLobby() async {
    final name = _nameController.text.trim().isEmpty
        ? 'Player 1'
        : _nameController.text.trim();
    await StorageService.saveUserName(name);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(
          userName: name,
          characterStyle: kCharacterStyles[0],
        ),
      ),
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
                          horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),

                          // Picklyball App Custom Logo Badge
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Glow
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withOpacity(0.35),
                                        blurRadius: 36,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                // Dual-ring Shield Logo
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldButton,
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.red.withOpacity(0.4),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(23),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.sports_tennis_rounded,
                                        color: AppColors.gold,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // App Title & Tagline
                          Center(
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.goldButton.createShader(
                                    Rect.fromLTWH(
                                        0, 0, bounds.width, bounds.height),
                                  ),
                                  child: const Text(
                                    'PICKLYBALL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      height: 0.95,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'APP',
                                  style: TextStyle(
                                    color: AppColors.redBright,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Underground Street Courts & Blitz Matches',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 44),

                          // Player Name / Street Tag Field
                          const Kicker('SET YOUR STREET TAG',
                              icon: Icons.edit_note_rounded),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.hairline, width: 1.5),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded,
                                    color: AppColors.gold, size: 22),
                                hintText: 'Enter player name...',
                                hintStyle: TextStyle(
                                  color: AppColors.textFaint,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Enter Game CTA Button
                          PrimaryCTA(
                            label: 'ENTER STREET COURTS',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _proceedToLobby,
                          ),

                          const Spacer(),
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
}
