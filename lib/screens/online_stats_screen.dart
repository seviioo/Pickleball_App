import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OnlineStatsScreen extends StatefulWidget {
  const OnlineStatsScreen({super.key});

  @override
  State<OnlineStatsScreen> createState() => _OnlineStatsScreenState();
}

class _OnlineStatsScreenState extends State<OnlineStatsScreen> {
  late Future<List<List<Map<String, dynamic>>>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = Future.wait([
      ApiService.getLeaderboard(),
      ApiService.getMatchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('ONLINE STATS'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load online stats.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          final leaderboard = snapshot.data![0];
          final history = snapshot.data![1];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle('LEADERBOARD'),
              if (leaderboard.isEmpty)
                _emptyText('No registered players yet.')
              else
                ...leaderboard.asMap().entries.map(
                      (entry) => _leaderboardRow(entry.key + 1, entry.value),
                    ),
              const SizedBox(height: 28),
              _sectionTitle('YOUR RECENT MATCHES'),
              if (history.isEmpty)
                _emptyText('Complete a match to see it here.')
              else
                ...history.map(_matchRow),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _leaderboardRow(int rank, Map<String, dynamic> player) => Card(
        color: const Color(0xFF1F232C),
        child: ListTile(
          leading: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
          title: Text(
            '${player['displayName'] ?? 'Player'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${player['wins'] ?? 0} wins  •  ${player['losses'] ?? 0} losses',
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Text(
            '${player['xp'] ?? 0} XP',
            style: const TextStyle(color: Colors.cyanAccent),
          ),
        ),
      );

  Widget _matchRow(Map<String, dynamic> match) => Card(
        color: const Color(0xFF1F232C),
        child: ListTile(
          leading: Icon(
            match['isVictory'] == true ? Icons.emoji_events : Icons.close,
            color: match['isVictory'] == true ? Colors.greenAccent : Colors.redAccent,
          ),
          title: Text(
            '${match['playerScore'] ?? 0} - ${match['opponentScore'] ?? 0}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'vs ${match['opponentName'] ?? 'Opponent'}',
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Text(
            '+${match['xpEarned'] ?? 0} XP',
            style: const TextStyle(color: Colors.cyanAccent),
          ),
        ),
      );

  Widget _emptyText(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(message, style: const TextStyle(color: Colors.white60)),
      );
}
