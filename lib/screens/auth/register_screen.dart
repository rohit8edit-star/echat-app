import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _userCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;

  Future<void> _register() async {
    if ([_nameCtrl, _userCtrl, _phoneCtrl, _emailCtrl, _passCtrl].any((c) => c.text.trim().isEmpty)) {
      _snack('All fields required'); return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.register(
        name: _nameCtrl.text.trim(), username: _userCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passCtrl.text.trim(),
      );
      setState(() => _loading = false);
      if (res['success'] && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => OtpScreen(email: _emailCtrl.text.trim(), type: 'register')));
      } else if (mounted) _snack(res['message'] ?? 'Error');
    } catch (_) { setState(() => _loading = false); _snack('Connection error'); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.backgroundDark),
        iconTheme: const IconThemeData(color: Color(AppColors.textPrimary)),
        title: const Text('Create Account', style: TextStyle(color: Color(AppColors.textPrimary))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Full Name'),    _field(_nameCtrl, 'Your name', Icons.person_outline),
            _label('Username'),     _field(_userCtrl, '@username', Icons.alternate_email),
            _label('Phone Number'), _field(_phoneCtrl, '+91 9999999999', Icons.phone_outlined, type: TextInputType.phone),
            _label('Email'),        _field(_emailCtrl, 'your@email.com', Icons.email_outlined, type: TextInputType.emailAddress),
            _label('Password'),
            TextField(
              controller: _passCtrl, obscureText: _obscure,
              style: const TextStyle(color: Color(AppColors.textPrimary)),
              decoration: InputDecoration(
                hintText: 'Create password', hintStyle: const TextStyle(color: Color(AppColors.textSecondary)),
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
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(t, style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 13)));

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) =>
    TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(color: Color(AppColors.textPrimary)),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(AppColors.textSecondary)),
        prefixIcon: Icon(icon, color: const Color(AppColors.iconColor)),
        filled: true, fillColor: const Color(AppColors.surfaceDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
}
