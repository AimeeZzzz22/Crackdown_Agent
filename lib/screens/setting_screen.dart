import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'notification_setting_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSettingBodyBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purple header
            Container(
              color: kSettingHeaderBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.chevron_left, color: kSettingText, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Setting',
                        style: GoogleFonts.merriweather(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: kSettingText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // List items
            _SettingTile(
              label: 'Notification',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingScreen())),
            ),
            _Divider(),
            _SettingTile(
              label: 'Privacy Policy',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
            _Divider(),
            _SettingTile(
              label: 'Account',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SettingTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: kSettingBodyBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.epilogue(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kSettingText,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: kSettingText, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: kSettingCustomBorder.withValues(alpha: 0.4),
        indent: 24, endIndent: 24);
  }
}
