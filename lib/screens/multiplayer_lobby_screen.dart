import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
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
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _roomPollTimer;
  bool _openingCourt = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _roomPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkRoomStatus(),
    );
  }

  Future<void> _checkRoomStatus() async {
    if (_openingCourt || !mounted) return;
    final status = await ApiService.getRoomStatus(widget.roomCode);
    if (status == 'in_progress') _openCourt();
  }

  Future<void> _connectSocket() async {
    final clientId = await StorageService.getOrCreateClientId();
    _socketSub = SocketService.instance.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'PLAYER_JOINED') {
        setState(() {
          opponentName = event['username'];
        });
      } else if (type == 'ROOM_STATE') {
        final players = event['players'];
        if (players is List && players.isNotEmpty) {
          setState(() {
            opponentName = players.first as String;
          });
        }
      } else if (type == 'MATCH_STARTED') {
        _openCourt();
      }
    });

    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
    SocketService.instance
        .connect(wsUrl, widget.roomCode, widget.userName, clientId);
  }

  void _startMatch() async {
    String? errorMessage;
    final success = await ApiService.startRoomMatch(
      widget.roomCode,
      widget.userName,
      onError: (message) => errorMessage = message,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Unable to start the match.'),
          backgroundColor: AppColors.redBright,
        ),
      );
    }
  }

  void _openCourt() {
    if (_openingCourt || !mounted) return;
    _openingCourt = true;
    _roomPollTimer?.cancel();
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

  @override
  void dispose() {
    _roomPollTimer?.cancel();
    _socketSub?.cancel();
    super.dispose();
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
