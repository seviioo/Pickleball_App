import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please Fill In All Fields (Username, Email, Age, Password)!'),
          backgroundColor: AppColors.redBright,
        ),
      );
      return;
    }

    // --- AGE VERIFICATION CHECK (7 - 60) ---
    if (age == null || age < 7 || age > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registration Failed: Age must be between 7 and 60 years old.'),
          backgroundColor: AppColors.redBright,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulated registration delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Save locally for testing before MongoDB wiring
    await StorageService.saveUserName(username);

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Show confirmation toast/snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account Created! Please Log In With Your Credentials.'),
        backgroundColor: Colors.green,
      ),
    );

    // Return back to LoginScreen
    Navigator.pop(context, {
      'username': username,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: streetAppBar('Create Player Profile'),
      body: StreetBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.gold,
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'New Player Registration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'Username / IGN',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _ageController,
                    hint: 'Age (7 - 60 years old)',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppColors.gold)
                      : PrimaryCTA(
                          label: 'Register',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _handleSignUp,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textFaint),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
