import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _snack('Fill all fields'); return;
    }
    final res = await context.read<AuthProvider>().login(_phoneCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(email: res['email'] ?? '', type: 'login')));
    } else {
      _snack(context.read<AuthProvider>().error ?? 'Error');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(AppColors.accent), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.chat_rounded, color: Colors.white, size: 44),
              )),
              const SizedBox(height: 20),
              const Center(child: Text('E-Chat', style: TextStyle(color: Color(AppColors.textPrimary), fontSize: 32, fontWeight: FontWeight.bold))),
              const Center(child: Text('Secure. Private. Simple.', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 13))),
              const SizedBox(height: 50),
              _label('Phone Number'),
              _field(_phoneCtrl, '+91 9999999999', Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 16),
              _label('Password'),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Color(AppColors.textPrimary)),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  hintStyle: const TextStyle(color: Color(AppColors.textSecondary)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(AppColors.iconColor)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: const Color(AppColors.iconColor)),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true, fillColor: const Color(AppColors.surfaceDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 28),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: Color(AppColors.textSecondary))),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Register', style: TextStyle(color: Color(AppColors.accent), fontWeight: FontWeight.bold)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 13)));

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) =>
    Padding(padding: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: c, keyboardType: type,
        style: const TextStyle(color: Color(AppColors.textPrimary)),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(AppColors.textSecondary)),
          prefixIcon: Icon(icon, color: const Color(AppColors.iconColor)),
          filled: true, fillColor: const Color(AppColors.surfaceDark),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ));
}
