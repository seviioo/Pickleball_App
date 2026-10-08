import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAccountNotFoundDialog(
        title: 'Missing Fields',
        message: 'Please enter both your Username/IGN and Password.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      await StorageService.saveUserName(username);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            userName: username,
            characterStyle: kCharacterStyles[0],
          ),
        ),
      );
    } else {
      _showAccountNotFoundDialog(
        title: 'Invalid Credentials',
        message:
            'Incorrect username or password. Please try again or create a profile.',
      );
    }
  }

  void _playOffline() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(isOffline: true),
      ),
    );
  }

  void _showAccountNotFoundDialog(
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: AppColors.redBright,
              fontWeight: FontWeight.w900,
              fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _navigateToSignUp();
            },
            child: const Text('CREATE PROFILE',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToSignUp() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
    if (result != null && result.containsKey('username')) {
      setState(() {
        _usernameController.text = result['username'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreetBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_tennis_rounded,
                      color: AppColors.gold, size: 64),
                  const SizedBox(height: 12),
                  const Text('Picklyball Street Blitz',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  const Text('Enter your Username / IGN to hit the court',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 32),
                  _buildTextField(
                      controller: _usernameController,
                      hint: 'Username / IGN',
                      icon: Icons.badge_outlined),
                  const SizedBox(height: 14),
                  _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppColors.gold)
                      : PrimaryCTA(
                          label: 'Log In',
                          icon: Icons.login_rounded,
                          onPressed: _handleLogin),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have a profile yet? ",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: _navigateToSignUp,
                        child: const Text('Register',
                            style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextButton.icon(
                    onPressed: _playOffline,
                    icon: const Icon(Icons.cloud_off),
                    label: const Text('PLAY OFFLINE'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline, width: 1.5)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textFaint),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      ),
    );
  }
}
