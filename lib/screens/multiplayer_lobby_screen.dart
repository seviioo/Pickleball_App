import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'multiplayer_court_screen.dart';

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
  String? opponentName;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
    SocketService.instance.connect(wsUrl, widget.roomCode, widget.userName);

    SocketService.instance.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'PLAYER_JOINED') {
        setState(() {
          opponentName = event['username'];
        });
      } else if (type == 'MATCH_STARTED') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerCourtScreen(
              userName: widget.userName,
              characterStyle: widget.characterStyle,
              roomCode: widget.roomCode,
              isHost: widget.isHost,
              opponentName: opponentName ?? 'Opponent',
            ),
          ),
        );
      }
    });
  }

  void _startMatch() async {
    final success =
        await ApiService.startRoomMatch(widget.roomCode, widget.userName);
    if (success) {
      SocketService.instance
          .sendEvent('START_MATCH', {'roomCode': widget.roomCode});
    }
  }

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
                                letterSpacing: 4),
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
                                    backgroundColor: AppColors.gold),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildPlayerSlot(
                  'HOST',
                  widget.isHost ? widget.userName : (opponentName ?? 'Host'),
                  true,
                ),
                const SizedBox(height: 16),
                _buildPlayerSlot(
                  'GUEST',
                  widget.isHost
                      ? (opponentName ?? 'Waiting for player...')
                      : widget.userName,
                  widget.isHost ? (opponentName != null) : true,
                ),
                const Spacer(),
                if (widget.isHost)
                  PrimaryCTA(
                    label: opponentName != null
                        ? 'START MULTIPLAYER MATCH'
                        : 'WAITING FOR OPPONENT...',
                    icon: Icons.play_arrow_rounded,
                    onPressed: opponentName != null ? _startMatch : () {},
                  )
                else
                  const Text('Waiting for Host to start the match...',
                      style: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSlot(String role, String name, bool connected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: connected ? AppColors.gold : AppColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: connected ? AppColors.gold : AppColors.hairline,
            child: Icon(Icons.person,
                color: connected ? Colors.black : Colors.white54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Icon(
            connected
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: connected ? Colors.greenAccent : AppColors.gold,
          ),
        ],
      ),
    );
  }
}
