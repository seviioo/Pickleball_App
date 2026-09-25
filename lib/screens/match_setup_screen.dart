import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import 'court_gameplay_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  final String? userName;
  final CharacterStyleData? characterStyle;
  final PaddleData? paddle;

  const MatchSetupScreen({
    Key? key,
    this.userName,
    this.characterStyle,
    this.paddle,
  }) : super(key: key);

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  double _selectedDupr = 3.5;
  int _targetScore = 11;
  PaddleData? _equippedPaddle;

  @override
  void initState() {
    super.initState();
    _equippedPaddle = widget.paddle;
    if (_equippedPaddle == null) {
      _loadPaddle();
    }
  }

  Future<void> _loadPaddle() async {
    final paddle = await StorageService.getEquippedPaddle();
    if (mounted) {
      setState(() {
        _equippedPaddle = paddle;
      });
    }
  }

  String get _duprTierLabel {
    if (_selectedDupr <= 2.5) return 'ROOKIE STREET';
    if (_selectedDupr <= 3.5) return 'AMATEUR HUSTLER';
    if (_selectedDupr <= 4.5) return 'PRO KITCHEN';
    return 'STREET LEGEND';
  }

  Color get _duprTierColor {
    if (_selectedDupr <= 2.5) return Colors.greenAccent;
    if (_selectedDupr <= 3.5) return Colors.cyanAccent;
    if (_selectedDupr <= 4.5) return Colors.purpleAccent;
    return Colors.amberAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MATCH SETUP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Opponent Skill Rating Card
              const Text(
                'OPPONENT DUPR RATING',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _duprTierColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _duprTierColor),
                          ),
                          child: Text(
                            _duprTierLabel,
                            style: TextStyle(
                              color: _duprTierColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          'DUPR ${_selectedDupr.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: _duprTierColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _duprTierColor,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: _duprTierColor,
                        overlayColor: _duprTierColor.withOpacity(0.2),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _selectedDupr,
                        min: 2.0,
                        max: 5.5,
                        divisions: 7,
                        onChanged: (val) {
                          setState(() => _selectedDupr = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Score Target Pill Buttons
              const Text(
                'MATCH SCORE TARGET',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [7, 11, 15].map((score) {
                  final isSelected = _targetScore == score;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _targetScore = score),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amberAccent
                              : const Color(0xFF16181D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amberAccent
                                : Colors.white12,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '$score PTS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 3. Equipped Paddle Spotlight
              if (_equippedPaddle != null) ...[
                const Text(
                  'EQUIPPED PADDLE',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181D),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_tennis,
                          color: Colors.purpleAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _equippedPaddle!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'POWER ${_equippedPaddle!.power} | CONTROL ${_equippedPaddle!.control} | SPIN ${_equippedPaddle!.spin}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // 4. Play Action CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final paddle = _equippedPaddle ??
                        await StorageService.getEquippedPaddle();

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourtGameplayScreen(
                          userName: widget.userName ?? 'Player',
                          paddle: paddle,
                          characterStyle:
                              widget.characterStyle ?? kCharacterStyles[0],
                          targetScore: _targetScore,
                          aiDupr: _selectedDupr,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.flash_on, color: Colors.black, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'SERVE OFF',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
