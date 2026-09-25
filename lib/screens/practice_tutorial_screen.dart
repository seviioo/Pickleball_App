import 'package:flutter/material.dart';

class PracticeTutorialScreen extends StatefulWidget {
  const PracticeTutorialScreen({Key? key}) : super(key: key);

  @override
  State<PracticeTutorialScreen> createState() => _PracticeTutorialScreenState();
}

class _PracticeTutorialScreenState extends State<PracticeTutorialScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _lessons = [
    {
      'title': 'THE KITCHEN RULE (NVZ)',
      'desc':
          'You cannot volley (hit the ball out of the air) while standing inside the 7-foot Non-Volley Zone (Kitchen).',
      'icon': 'warning',
    },
    {
      'title': 'DOUBLE BOUNCE RULE',
      'desc':
          'The serve must bounce before being returned, and the return hit must bounce before being played.',
      'icon': 'repeat',
    },
    {
      'title': 'DINKING & PACING',
      'desc':
          'Soft un-attackable shots hit into your opponent\'s kitchen force them to lift the ball high for an easy smash.',
      'icon': 'sports_tennis',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'STREET ACADEMY',
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
            children: [
              // Lesson Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lesson['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lesson['desc']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('PREVIOUS',
                          style: TextStyle(color: Colors.white54)),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep < _lessons.length - 1) {
                        setState(() => _currentStep++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentStep == _lessons.length - 1
                          ? 'FINISH'
                          : 'NEXT LESSON',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
