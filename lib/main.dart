import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  // Auto-login with demo account on web for quick preview
  if (kIsWeb) AuthService.instance.signInAsDemo();
  runApp(const CrackdownApp());
}

class CrackdownApp extends StatelessWidget {
  const CrackdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MaterialApp(
        title: 'Crackdown',
        debugShowCheckedModeBanner: false,
        home: _PhoneFrame(),
      );
    }

    final Widget home = AuthService.instance.isLoggedIn
        ? const HomeScreen()
        : const SignUpScreen();

    return MaterialApp(
      title: 'Crackdown',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: home,
    );
  }
}

/// Phone-shaped frame for the web demo — keeps the app at iPhone 14 dimensions.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame();

  @override
  Widget build(BuildContext context) {
    const phoneW = 390.0;
    const phoneH = 844.0;
    const bezel = 14.0;
    const cornerRadius = 50.0;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      body: Center(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // Scale down when the viewport is smaller than the phone frame
            final sx = (constraints.maxWidth - 48) / (phoneW + bezel * 2);
            final sy = (constraints.maxHeight - 48) / (phoneH + bezel * 2);
            final scale = (sx < sy ? sx : sy).clamp(0.0, 1.0);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: phoneW + bezel * 2,
                height: phoneH + bezel * 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(cornerRadius + bezel),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 60,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7B5EA7).withValues(alpha: 0.2),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF3A3A5C), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(bezel),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    child: SizedBox(
                      width: phoneW,
                      height: phoneH,
                      child: MediaQuery(
                        data: const MediaQueryData(
                          size: Size(phoneW, phoneH),
                          devicePixelRatio: 1,
                          padding: EdgeInsets.only(top: 47, bottom: 34),
                          viewPadding: EdgeInsets.only(top: 47, bottom: 34),
                        ),
                        child: MaterialApp(
                          debugShowCheckedModeBanner: false,
                          theme: ThemeData(useMaterial3: true),
                          home: AuthService.instance.isLoggedIn
                              ? const HomeScreen()
                              : const SignUpScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
