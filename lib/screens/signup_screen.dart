import 'package:flutter/material.dart';
import '../services/api_service.dart';
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText) ?? 0;

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        ageText.isEmpty) {
      _showError('Please Fill In All Fields!');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Invalid email address format (must be name@example.com).');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    if (age < 7 || age > 60) {
      _showError(
          'Registration Failed: Age must be between 7 and 60 years old.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.register(
      username: username,
      email: email,
      password: password,
      age: age,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      await StorageService.saveUserName(username);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Account Created! Please Log In With Your Credentials.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, {'username': username});
    } else {
      _showError(
          'Registration Failed. Check connection or username/email duplicate.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.redBright),
    );
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
                  const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.gold, size: 54),
                  const SizedBox(height: 12),
                  const Text('New Player Registration',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  _buildTextField(
                      controller: _usernameController,
                      hint: 'Username / IGN',
                      icon: Icons.badge_outlined),
                  const SizedBox(height: 14),
                  _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _buildTextField(
                      controller: _ageController,
                      hint: 'Age (7 - 60 years old)',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number),
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
                          label: 'Register',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _handleSignUp),
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
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
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
