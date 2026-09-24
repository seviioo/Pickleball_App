import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'court_gameplay_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  final String userName;
  final PaddleData paddle;
  final CharacterStyleData characterStyle;

  const MatchSetupScreen({
    super.key,
    required this.userName,
    required this.paddle,
    required this.characterStyle,
  });

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  int targetScore = 11;
  double aiDupr = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      extendBodyBehindAppBar: true,
      appBar: streetAppBar('MATCH SETUP'),
      body: StreetBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player & Equipment Summary
                StreetCard(
                  borderColor: AppColors.gold.withOpacity(0.35),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldButton,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: widget.characterStyle.outfitPrimary,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.sports_tennis_rounded,
                                  size: 13, color: AppColors.gold),
                              const SizedBox(width: 4),
                              Text(
                                widget.paddle.name,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                const Kicker('TARGET SCORE  ·  WIN BY 2',
                    color: AppColors.textSecondary, icon: Icons.flag_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildScoreCard(5, '5', 'Quick Sprint'),
                    const SizedBox(width: 10),
                    _buildScoreCard(11, '11', 'Regulation'),
                    const SizedBox(width: 10),
                    _buildScoreCard(15, '15', 'Pro Slam'),
                  ],
                ),

                const SizedBox(height: 26),

                const Kicker('AI THREAT LEVEL  ·  DUPR RATING',
                    color: AppColors.textSecondary,
                    icon: Icons.local_fire_department_rounded),
                const SizedBox(height: 12),
                _buildDuprTile(
                  rating: 2.5,
                  title: 'ROOKIE',
                  ratingLabel: '2.5 DUPR',
                  subtitle: 'Casual pace, relaxed reaction time',
                  color: AppColors.win,
                  icon: Icons.self_improvement_rounded,
                ),
                const SizedBox(height: 10),
                _buildDuprTile(
                  rating: 4.0,
                  title: 'PRO TOUR',
                  ratingLabel: '4.0 DUPR',
                  subtitle: 'Sharp dinks, aggressive baseline drives',
                  color: const Color(0xFF38BDF8),
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(height: 10),
                _buildDuprTile(
                  rating: 5.5,
                  title: 'TITAN',
                  ratingLabel: '5.5+ DUPR',
                  subtitle: 'Relentless speed, strict kitchen positioning',
                  color: AppColors.redBright,
                  icon: Icons.whatshot_rounded,
                ),

                const SizedBox(height: 32),

                PrimaryCTA(
                  label: 'STEP ONTO COURT',
                  icon: Icons.sports_kabaddi_rounded,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourtGameplayScreen(
                          userName: widget.userName,
                          paddle: widget.paddle,
                          characterStyle: widget.characterStyle,
                          targetScore: targetScore,
                          aiDupr: aiDupr,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(int pts, String title, String subtitle) {
    final bool isSelected = targetScore == pts;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => targetScore = pts),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.goldButton : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.hairline,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : AppColors.textFaint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuprTile({
    required double rating,
    required String title,
    required String ratingLabel,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final bool isSelected = aiDupr == rating;
    return GestureDetector(
      onTap: () => setState(() => aiDupr = rating),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.hairline,
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? color : AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textFaint, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? color : AppColors.hairline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
