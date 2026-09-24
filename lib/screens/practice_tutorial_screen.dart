import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'court_gameplay_screen.dart';

class PracticeTutorialScreen extends StatefulWidget {
  final String userName;
  final PaddleData paddle;

  const PracticeTutorialScreen({
    super.key,
    required this.userName,
    required this.paddle,
  });

  @override
  State<PracticeTutorialScreen> createState() => _PracticeTutorialScreenState();
}

class _PracticeTutorialScreenState extends State<PracticeTutorialScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': 'SERVING & RALLIES',
      'icon': Icons.sports_tennis_rounded,
      'body':
          'Tap any attack button (DRIVE, ROLL, SPEED UP, SMASH) to serve or strike the ball back across the net.',
    },
    {
      'title': 'NVZ / KITCHEN FAULTS',
      'icon': Icons.warning_amber_rounded,
      'body':
          'Be careful near the kitchen line! Stepping too far into the Non-Volley Zone while taking a shot will cause a fault.',
    },
    {
      'title': 'SHOT TYPES & TIMING',
      'icon': Icons.bolt_rounded,
      'body':
          'Use DRIVES for flat speed, ROLLS for top-spin arcs, SPEED UPs for quick surprises, and SMASHES for high aggressive finishes.',
    },
    {
      'title': 'CUSTOM OUTFITS & GEAR',
      'icon': Icons.checkroom_rounded,
      'body':
          'Customize your player name, paddle stats, and 2D outfit color scheme inside the PROFILE menu.',
    },
  ];

  void _startPracticeCourt() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CourtGameplayScreen(
          userName: widget.userName,
          paddle: widget.paddle,
          characterStyle: kCharacterStyles[0],
          targetScore: 11,
          aiDupr: 2.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _tutorialSteps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.void_,
      extendBodyBehindAppBar: true,
      appBar: streetAppBar('PRACTICE & TUTORIAL'),
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              children: [
                Row(
                  children: List.generate(_tutorialSteps.length, (i) {
                    final active = i <= _currentStep;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            right: i == _tutorialSteps.length - 1 ? 0 : 6),
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: active ? AppColors.goldButton : null,
                          color: active ? null : AppColors.hairline,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: StreetCard(
                    padding: const EdgeInsets.all(24),
                    borderColor: AppColors.gold.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(icon: step['icon'], size: 52),
                        const SizedBox(height: 18),
                        Kicker(
                            'STEP ${_currentStep + 1} OF ${_tutorialSteps.length}'),
                        const SizedBox(height: 6),
                        Text(
                          step['title'],
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step['body'],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: SecondaryButton(
                          label: 'PREVIOUS',
                          icon: Icons.arrow_back_rounded,
                          accent: AppColors.textSecondary,
                          onPressed: () => setState(() => _currentStep--),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 2,
                      child: PrimaryCTA(
                        label: _currentStep < _tutorialSteps.length - 1
                            ? 'NEXT'
                            : 'START PRACTICE COURT',
                        icon: _currentStep < _tutorialSteps.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.play_arrow_rounded,
                        height: 54,
                        onPressed: () {
                          if (_currentStep < _tutorialSteps.length - 1) {
                            setState(() => _currentStep++);
                          } else {
                            _startPracticeCourt();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
