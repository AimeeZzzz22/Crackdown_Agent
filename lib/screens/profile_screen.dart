import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import 'profile_edit_screen.dart';
import 'signup_screen.dart';
import 'change_password_screen.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Seeded from AuthService; user can override via Edit
  late String firstName;
  late String lastName;
  late String userName;
  late String email;
  String phone = '';
  String birthday = '';

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    userName = user?.username ?? '';
    email = user?.email ?? '';
    // Split username into first/last if possible
    final parts = userName.split('.');
    firstName = parts.isNotEmpty ? _capitalize(parts[0]) : '';
    lastName = parts.length > 1 ? _capitalize(parts[1]) : '';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _signOut() {
    AuthService.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSettingBodyBg,
      body: Column(
        children: [
          // Purple header — no back button (this is a tab)
          Container(
            color: kSettingHeaderBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.merriweather(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kSettingText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingScreen()),
                      ),
                      child: Icon(Icons.settings_outlined,
                          color: kSettingText, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Avatar
          Container(
            color: kSettingHeaderBg,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: kCheckbox.withValues(alpha: 0.3),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: GoogleFonts.merriweather(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(
                          firstName: firstName,
                          lastName: lastName,
                          userName: userName,
                          email: email,
                          phone: phone,
                          birthday: birthday,
                          onSave: (f, l, u, e, p, b) => setState(() {
                            firstName = f;
                            lastName = l;
                            userName = u;
                            email = e;
                            phone = p;
                            birthday = b;
                          }),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.epilogue(
                      fontSize: 12,
                      color: kSettingText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _ProfileField(
                    label: 'Name',
                    value: [firstName, lastName]
                        .where((s) => s.isNotEmpty)
                        .join(' '),
                  ),
                  _ProfileField(label: 'Username', value: userName),
                  _ProfileField(label: 'Email Address', value: email),
                  _ProfileField(label: 'Phone Number', value: phone),
                  _ProfileField(
                    label: 'Birthday',
                    value: birthday,
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  // Change Password
                  _ActionRow(
                    label: 'Change Password',
                    icon: Icons.lock_outline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sign Out
                  _ActionRow(
                    label: 'Sign Out',
                    icon: Icons.logout,
                    color: kTodoRequired,
                    onTap: _signOut,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _ProfileField({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.epilogue(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kSettingTitle)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kSettingCustomBorder),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: kSettingIcon),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    value.isEmpty ? '—' : value,
                    style: GoogleFonts.epilogue(
                        fontSize: 14, color: kSettingText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kSettingTitle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kSettingCustomBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.epilogue(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: c),
          ],
        ),
      ),
    );
  }
}
