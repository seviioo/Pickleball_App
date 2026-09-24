import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'court_gameplay_screen.dart';

class TournamentScreen extends StatefulWidget {
  final String userName;
  final PaddleData paddle;
  final CharacterStyleData characterStyle;

  const TournamentScreen({
    super.key,
    required this.userName,
    required this.paddle,
    required this.characterStyle,
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  int currentRound = 1;

  final List<Map<String, dynamic>> tournamentRounds = [
    {
      'round': 1,
      'title': 'QUARTERFINALS',
      'opponent': 'Rook "The Wall" Vance',
      'dupr': 2.8,
      'reward': 150,
    },
    {
      'round': 2,
      'title': 'SEMIFINALS',
      'opponent': 'Maya "Alley Queen" Lin',
      'dupr': 3.8,
      'reward': 350,
    },
    {
      'round': 3,
      'title': 'STREET FINALS',
      'opponent': 'Jax "Spin Boss" Steele',
      'dupr': 4.8,
      'reward': 1000,
    },
  ];

  void _startRoundMatch(Map<String, dynamic> roundData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourtGameplayScreen(
          userName: widget.userName,
          paddle: widget.paddle,
          characterStyle: widget.characterStyle,
          targetScore: 11,
          aiDupr: roundData['dupr'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      extendBodyBehindAppBar: true,
      appBar: streetAppBar('UNDERGROUND BRACKET'),
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Championship banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.16),
                        AppColors.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.5), width: 1.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldButton,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.4),
                                blurRadius: 14),
                          ],
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: Colors.black, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STREET CHAMPIONSHIP',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3)),
                            SizedBox(height: 2),
                            Text(
                                'Win 3 consecutive matches to claim the Street Cash Prize.',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                    height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ListView.builder(
                    itemCount: tournamentRounds.length,
                    itemBuilder: (context, index) {
                      final item = tournamentRounds[index];
                      final bool isCurrent = item['round'] == currentRound;
                      final bool isLocked = item['round'] > currentRound;
                      final bool isDone = item['round'] < currentRound;
                      final bool isLast = index == tournamentRounds.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bracket connector rail
                            SizedBox(
                              width: 34,
                              child: Column(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone
                                          ? AppColors.gold
                                          : (isCurrent
                                              ? AppColors.redBright
                                              : AppColors.surfaceRaised),
                                      border: Border.all(
                                        color: isLocked
                                            ? AppColors.hairline
                                            : Colors.transparent,
                                        width: 1.4,
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                  color: AppColors.red
                                                      .withOpacity(0.45),
                                                  blurRadius: 10),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      isDone
                                          ? Icons.check_rounded
                                          : (isLocked
                                              ? Icons.lock_rounded
                                              : Icons.play_arrow_rounded),
                                      color: isLocked
                                          ? AppColors.textFaint
                                          : (isDone
                                              ? Colors.black
                                              : Colors.white),
                                      size: 18,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        color: isDone
                                            ? AppColors.gold.withOpacity(0.6)
                                            : AppColors.hairline,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Round card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Opacity(
                                  opacity: isLocked ? 0.55 : 1.0,
                                  child: StreetCard(
                                    borderColor: isCurrent
                                        ? AppColors.redBright
                                        : AppColors.hairline,
                                    borderWidth: isCurrent ? 1.6 : 1.2,
                                    shadows: isCurrent
                                        ? [
                                            BoxShadow(
                                                color: AppColors.red
                                                    .withOpacity(0.18),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6)),
                                          ]
                                        : null,
                                    onTap: isCurrent
                                        ? () => _startRoundMatch(item)
                                        : null,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Kicker(
                                                item['title'],
                                                color: isCurrent
                                                    ? AppColors.redBright
                                                    : AppColors.textFaint,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item['opponent'],
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 15.5,
                                                    fontWeight:
                                                        FontWeight.w900),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .surfaceRaised,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      'DUPR ${item['dupr']}',
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                      Icons
                                                          .monetization_on_rounded,
                                                      size: 13,
                                                      color: AppColors.gold),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '+${item['reward']}',
                                                    style: const TextStyle(
                                                        color: AppColors.gold,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.redButton,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                PrimaryCTA(
                  label: 'ENTER BRACKET MATCH',
                  icon: Icons.sports_kabaddi_rounded,
                  gradient: AppColors.redButton,
                  glowColor: AppColors.red,
                  foreground: Colors.white,
                  onPressed: () =>
                      _startRoundMatch(tournamentRounds[currentRound - 1]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
