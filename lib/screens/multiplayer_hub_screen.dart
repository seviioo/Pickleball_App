import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'multiplayer_lobby_screen.dart';

class MultiplayerHubScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;

  const MultiplayerHubScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
  });

  @override
  State<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends State<MultiplayerHubScreen> {
  final TextEditingController _codeController = TextEditingController();

  // GENERATE RANDOM ALPHANUMERIC ROOM CODE (e.g., K9B2X7)
  String _generateRandomRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  void _createRoomUI() {
    final roomCode = _generateRandomRoomCode();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerLobbyScreen(
          userName: widget.userName,
          characterStyle: widget.characterStyle,
          roomCode: roomCode,
          isHost: true,
        ),
      ),
    );
  }

  void _joinRoomUI() {
    final String code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid room code'),
          backgroundColor: AppColors.redBright,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerLobbyScreen(
          userName: widget.userName,
          characterStyle: widget.characterStyle,
          roomCode: code,
          isHost: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: streetAppBar('ONLINE MULTIPLAYER'),
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                const Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppColors.gold,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'REAL-TIME STREET MATCHES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Challenge real players live over room codes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),
                PrimaryCTA(
                  label: 'CREATE MATCH ROOM',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: _createRoomUI,
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.hairline)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR JOIN WITH CODE',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.hairline)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline, width: 1.5),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ENTER CODE (e.g. K9B2X7)',
                      hintStyle: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceRaised,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.gold, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _joinRoomUI,
                    icon:
                        const Icon(Icons.login_rounded, color: AppColors.gold),
                    label: const Text(
                      'JOIN ROOM',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
