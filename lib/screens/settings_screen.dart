import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUserName;

  const SettingsScreen({
    super.key,
    required this.currentUserName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _username;
  double _musicVolume = 80;
  double _sfxVolume = 100;
  double _hapticVolume = 70;

  @override
  void initState() {
    super.initState();
    _username = widget.currentUserName;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedName = await StorageService.getUserName();
    if (savedName != null && savedName.isNotEmpty) {
      setState(() => _username = savedName);
    }
  }

  // --- Profile Edit Bottom Sheet ---
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _username);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EDIT PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Street Tag / IGN',
                labelStyle: const TextStyle(color: AppColors.gold),
                prefixIcon:
                    const Icon(Icons.badge_outlined, color: AppColors.gold),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    await StorageService.saveUserName(newName);
                    setState(() => _username = newName);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Permanent Delete Account Action ---
  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.redBright, width: 2),
        ),
        title: const Text(
          'DELETE STREET PROFILE?',
          style: TextStyle(
              color: AppColors.redBright, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account, saved inventory, and stats. Type your username to confirm:',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _username,
                hintStyle: const TextStyle(color: AppColors.textFaint),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.redBright),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.redBright),
            onPressed: () async {
              if (confirmController.text.trim() == _username) {
                // Clear user data
                await StorageService.saveUserName('');
                if (!mounted) return;
                Navigator.pop(context); // close dialog

                // Return to LoginScreen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Username match failed! Account not deleted.'),
                    backgroundColor: AppColors.redBright,
                  ),
                );
              }
            },
            child: const Text('DELETE PROFILE',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Logout Action ---
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: streetAppBar('STREET SETTINGS'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROFILE MANAGEMENT',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Profile Card (Editable)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: ListTile(
                onTap: _showEditProfileDialog,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.gold,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                title: Text(
                  _username.isEmpty ? 'Street Legend' : _username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                subtitle: const Text(
                  'Tap edit button to change Street Tag',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.edit, color: AppColors.gold),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'AUDIO & TACTILE CONTROLS',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildSliderCard('Music Volume', _musicVolume, Colors.cyan,
                (v) => setState(() => _musicVolume = v)),
            const SizedBox(height: 10),
            _buildSliderCard('SFX Effects', _sfxVolume, AppColors.gold,
                (v) => setState(() => _sfxVolume = v)),
            const SizedBox(height: 10),
            _buildSliderCard('Haptic Feedback', _hapticVolume,
                Colors.purpleAccent, (v) => setState(() => _hapticVolume = v)),

            const SizedBox(height: 24),
            const Text(
              'DANGER ZONE',
              style: TextStyle(
                  color: AppColors.redBright,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.redBright.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Log Out',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Return to login screen',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.logout, color: AppColors.gold),
                    onTap: _handleLogout,
                  ),
                  const Divider(color: AppColors.hairline, height: 1),
                  ListTile(
                    title: const Text('Delete Street Profile',
                        style: TextStyle(
                            color: AppColors.redBright,
                            fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Permanently wipes user account and saved data',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redBright),
                      onPressed: _showDeleteAccountDialog,
                      child: const Text('DELETE',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard(
      String title, double value, Color color, ValueChanged<double> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${value.round()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: color,
            inactiveColor: AppColors.hairline,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
