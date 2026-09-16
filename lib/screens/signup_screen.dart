import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/crackdown_logo.dart';
import '../widgets/auth_text_field.dart';
import '../services/auth_service.dart';
import '../utils/validation.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _keepSignedIn = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<String> _errors = [];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    setState(() => _errors = []);

    final errors = AuthService.instance.signUp(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    showSuccessSnackBar(context, 'Account created! Please sign in.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _handleDemoLogin() {
    AuthService.instance.signInAsDemo();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background + form (always fully visible) ──────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBackgroundTop, kBackgroundBottom],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Center(child: CrackdownLogo()),
                    const SizedBox(height: 36),
                    Text(
                      'CREATE ACCOUNT BY USING EMAIL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kCrackText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      hint: 'Username',
                      icon: Icons.person_outline,
                      controller: _usernameController,
                      onChanged: (_) => setState(() => _errors = []),
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      hint: 'Emailaddress@gmail.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _errors = []),
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
                      onChanged: (_) => setState(() => _errors = []),
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _confirmPasswordController,
                      onChanged: (_) => setState(() => _errors = []),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _keepSignedIn = !_keepSignedIn),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _keepSignedIn
                                  ? kCheckbox
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: kCheckbox, width: 2),
                            ),
                            child: _keepSignedIn
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Keep me signed in',
                            style:
                                TextStyle(color: kCrackText, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kButtonBackground,
                          foregroundColor: kButtonText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Create Account',
                            style: GoogleFonts.epilogue(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            children: [
                              const TextSpan(
                                  text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                    color: kForgotHighlight,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DemoButton(onTap: _handleDemoLogin),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating error notification — overlays form without pushing it ──
          if (_errors.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC0392B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline,
                            color: Color(0xFFC0392B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _errors
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '• $e',
                                      style: GoogleFonts.epilogue(
                                        fontSize: 13,
                                        color: const Color(0xFFC0392B),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _errors = []),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.close,
                              size: 20, color: Color(0xFFC0392B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DemoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white38, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('⚡', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Try Demo — skip sign up',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
