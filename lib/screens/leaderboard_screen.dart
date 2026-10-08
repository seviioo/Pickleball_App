import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  final String currentUserName;

  const LeaderboardScreen({super.key, required this.currentUserName});

  // Mock static data for pure UI layout presentation
  static const List<Map<String, dynamic>> _mockLeaderboard = [
    {'username': 'Viper_Ace', 'wins': 142, 'losses': 18, 'rating': 2450},
    {'username': 'PickleGod', 'wins': 118, 'losses': 22, 'rating': 2210},
    {'username': 'NetRider', 'wins': 95, 'losses': 31, 'rating': 1980},
    {'username': 'CourtKing', 'wins': 84, 'losses': 40, 'rating': 1820},
    {'username': 'SmashPro', 'wins': 72, 'losses': 45, 'rating': 1690},
    {'username': 'StreetLegend', 'wins': 50, 'losses': 20, 'rating': 1500},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: streetAppBar('GLOBAL LEADERBOARD'),
      body: StreetBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mockLeaderboard.length,
                  itemBuilder: (context, index) {
                    final item = _mockLeaderboard[index];
                    final rank = index + 1;
                    final isMe = item['username'] == currentUserName;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.gold.withOpacity(0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMe ? AppColors.gold : AppColors.hairline,
                          width: isMe ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: rank == 1
                                    ? AppColors.gold
                                    : (rank == 2
                                        ? Colors.grey.shade300
                                        : (rank == 3
                                            ? Colors.orangeAccent
                                            : Colors.white70)),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['username'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${item['wins']} Wins • ${item['losses']} Losses',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item['rating']}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // CURRENT PLAYER RANK BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceRaised,
                  border:
                      Border(top: BorderSide(color: AppColors.gold, width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Kicker('YOUR GLOBAL RANK'),
                        Text(
                          '#6 $currentUserName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Rating: 1500',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
