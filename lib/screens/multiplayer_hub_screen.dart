import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';
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
  bool _isLoading = false;

  String _generateRandomRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _createRoom() async {
    final roomCode = _generateRandomRoomCode();
    setState(() => _isLoading = true);

    String? errorMessage;
    final result = await ApiService.createRoom(
      roomCode,
      widget.userName,
      onError: (message) => errorMessage = message,
    );
    setState(() => _isLoading = false);

    if (result != null) {
      if (!mounted) return;
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
    } else {
      _showError(errorMessage ?? 'Failed to create room.');
    }
  }

  Future<void> _joinRoom() async {
    final String code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      _showError('Please enter a valid room code.');
      return;
    }

    setState(() => _isLoading = true);
    String? errorMessage;
    final result = await ApiService.joinRoom(
      code,
      widget.userName,
      onError: (message) => errorMessage = message,
    );
    setState(() => _isLoading = false);

    if (result != null) {
      if (!mounted) return;
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
    } else {
      _showError(errorMessage ?? 'Unable to join the room.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.redBright),
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
                const Icon(Icons.wifi_tethering_rounded,
                    color: AppColors.gold, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'REAL-TIME STREET MATCHES',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Challenge real players live over the network',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 36),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.gold)
                    : PrimaryCTA(
                        label: 'CREATE MATCH ROOM',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: _createRoom,
                      ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.hairline)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR JOIN WITH CODE',
                          style: TextStyle(
                              color: AppColors.textFaint,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
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
                        letterSpacing: 4),
                    decoration: const InputDecoration(
                      hintText: 'ENTER CODE (e.g. K9B2X7)',
                      hintStyle: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 14,
                          letterSpacing: 1),
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
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _joinRoom,
                    icon:
                        const Icon(Icons.login_rounded, color: AppColors.gold),
                    label: const Text('JOIN ROOM',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
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
