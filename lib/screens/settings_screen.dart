import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUserName;
  final Function(String newName)? onUserNameChanged;
  final VoidCallback? onResetProgress;

  const SettingsScreen({
    Key? key,
    this.currentUserName = 'Street Legend',
    this.onUserNameChanged,
    this.onResetProgress,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _userName;
  double _musicVolume = 0.8;
  double _sfxVolume = 1.0;
  double _hapticIntensity = 0.7;

  @override
  void initState() {
    super.initState();
    _userName = widget.currentUserName;
  }

  void _triggerHapticPulse() {
    if (_hapticIntensity > 0.1) {
      HapticFeedback.selectionClick();
    }
  }

  void _showEditTagDialog() {
    final TextEditingController controller =
        TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
          title: const Text(
            'UPDATE STREET TAG',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Enter new player tag...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.cyanAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty) {
                  setState(() => _userName = newTag);
                  if (widget.onUserNameChanged != null) {
                    widget.onUserNameChanged!(newTag);
                  }
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'SAVE',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmationModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text(
                'RESET PROGRESS',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure? This will wipe all unlocked paddles, Street Rep level, coins, and tournament wins. This action cannot be undone.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onResetProgress != null) {
                  widget.onResetProgress!();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Street progress has been reset.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'WIPE DATA',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'STREET SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Profile Section
            _buildSectionHeader('PROFILE MANAGEMENT', Icons.person),
            const SizedBox(height: 10),
            _buildProfileTile(),

            const SizedBox(height: 24),

            // 2. Audio & Haptics Section
            _buildSectionHeader('AUDIO & TACTILE CONTROLS', Icons.tune),
            const SizedBox(height: 10),
            _buildSliderCard(
              title: 'Music Volume',
              value: _musicVolume,
              icon: Icons.music_note,
              activeColor: Colors.cyanAccent,
              onChanged: (val) {
                setState(() => _musicVolume = val);
              },
            ),
            const SizedBox(height: 12),
            _buildSliderCard(
              title: 'SFX Effects',
              value: _sfxVolume,
              icon: Icons.volume_up,
              activeColor: Colors.amberAccent,
              onChanged: (val) {
                setState(() => _sfxVolume = val);
              },
            ),
            const SizedBox(height: 12),
            _buildSliderCard(
              title: 'Haptic Feedback',
              value: _hapticIntensity,
              icon: Icons.vibration,
              activeColor: Colors.purpleAccent,
              onChanged: (val) {
                setState(() => _hapticIntensity = val);
                _triggerHapticPulse();
              },
            ),

            const SizedBox(height: 32),

            // 3. Danger Zone Section
            _buildSectionHeader('DANGER ZONE', Icons.report_problem,
                color: Colors.redAccent),
            const SizedBox(height: 10),
            _buildResetCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {Color color = Colors.white54}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.cyanAccent.withOpacity(0.15),
            child: const Icon(Icons.person, color: Colors.cyanAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap edit button to change Street Tag',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditTagDialog,
            icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required IconData icon,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: activeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: Colors.white10,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clear Saved Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wipes coins, paddles, and tournament stats.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showResetConfirmationModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'RESET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
