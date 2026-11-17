import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              auth.isAuthenticated ? const MainNavScreen() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary,
              cs.primary.withOpacity(0.78),
              cs.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.42, 1],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(
              children: [
              const Spacer(flex: 2),
              // Logo
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.jpg',
                    height: 96,
                    width: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.newspaper_rounded,
                          color: cs.primary, size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tin tức & Thời tiết',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Cập nhật mỗi ngày',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Stay informed • Stay prepared',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(flex: 2),
              // Loading bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: LinearProgressIndicator(
                  backgroundColor: cs.outlineVariant,
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Phiên bản 1.0.0',
                style:
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
