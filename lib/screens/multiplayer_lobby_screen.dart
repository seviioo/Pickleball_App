import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;
  final String roomCode;
  final bool isHost;

  const MultiplayerLobbyScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
    required this.roomCode,
    required this.isHost,
  });

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  // Pure UI state to toggle second player presence for layout testing
  bool _mockOpponentJoined = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: streetAppBar('MATCH LOBBY'),
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // INVITATION CODE CARD
                StreetCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Kicker('SHARE INVITATION CODE'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.roomCode,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                color: Colors.white70),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.roomCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Room code copied!'),
                                  backgroundColor: AppColors.gold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // LOBBY SLOTS
                _buildPlayerSlot(
                  role: 'HOST',
                  name: widget.isHost ? widget.userName : 'Rival_Host',
                  isConnected: true,
                ),
                const SizedBox(height: 16),
                _buildPlayerSlot(
                  role: 'GUEST',
                  name: widget.isHost
                      ? (_mockOpponentJoined
                          ? 'StreetKing_99'
                          : 'Waiting for player...')
                      : widget.userName,
                  isConnected: widget.isHost ? _mockOpponentJoined : true,
                ),

                const SizedBox(height: 20),

                // UI TESTING TOGGLE (SIMULATE OPPONENT JOINING)
                if (widget.isHost)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _mockOpponentJoined = !_mockOpponentJoined;
                      });
                    },
                    icon: const Icon(Icons.bug_report,
                        color: AppColors.textFaint, size: 16),
                    label: Text(
                      _mockOpponentJoined
                          ? 'UI Test: Remove Guest'
                          : 'UI Test: Simulate Guest Join',
                      style: const TextStyle(
                          color: AppColors.textFaint, fontSize: 12),
                    ),
                  ),

                const Spacer(),

                // ACTION BUTTON
                if (widget.isHost)
                  PrimaryCTA(
                    label: _mockOpponentJoined
                        ? 'START MULTIPLAYER MATCH'
                        : 'WAITING FOR OPPONENT...',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _mockOpponentJoined
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Starting match UI...')),
                            );
                          }
                        : () {},
                  )
                else
                  const Text(
                    'Waiting for Host to start the match...',
                    style: TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSlot({
    required String role,
    required String name,
    required bool isConnected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.gold : AppColors.hairline,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isConnected ? AppColors.gold : AppColors.hairline,
            child: Icon(
              Icons.person,
              color: isConnected ? Colors.black : Colors.white54,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isConnected
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: isConnected ? Colors.greenAccent : AppColors.gold,
          ),
        ],
      ),
    );
  }
}
