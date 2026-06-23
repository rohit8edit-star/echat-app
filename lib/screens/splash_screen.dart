import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await context.read<AuthProvider>().checkLogin();
    if (!mounted) return;
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen()));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.accent),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: const Color(AppColors.accent).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 24),
                const Text('E-Chat', style: TextStyle(color: Color(AppColors.textPrimary), fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text('Secure. Private. Simple.', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 14)),
                const SizedBox(height: 60),
                const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Color(AppColors.accent), strokeWidth: 2.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
