import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String type; // register | login
  const OtpScreen({super.key, required this.email, required this.type});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void initState() { super.initState(); _focusNodes[0].requestFocus(); }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) { _snack('Enter complete OTP'); return; }
    setState(() => _loading = true);
    try {
      if (widget.type == 'register') {
        final res = await ApiService.verifyRegisterOTP(widget.email, _otp);
        setState(() => _loading = false);
        if (res['success'] && mounted) {
          await ApiService.saveToken(res['token']);
          final user = await ApiService.getProfile();
          if (user != null && mounted) context.read<AuthProvider>().setUser(user);
          _goHome();
        } else if (mounted) _snack(res['message'] ?? 'Wrong OTP');
      } else {
        final ok = await context.read<AuthProvider>().verifyLoginOTP(widget.email, _otp);
        setState(() => _loading = false);
        if (ok && mounted) _goHome();
        else if (mounted) _snack(context.read<AuthProvider>().error ?? 'Wrong OTP');
      }
    } catch (_) { setState(() => _loading = false); _snack('Connection error'); }
  }

  void _goHome() => Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(backgroundColor: const Color(AppColors.backgroundDark),
          iconTheme: const IconThemeData(color: Color(AppColors.textPrimary))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.email_outlined, color: Color(AppColors.accent), size: 48),
            const SizedBox(height: 20),
            const Text('Verify OTP', style: TextStyle(color: Color(AppColors.textPrimary), fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enter the 6-digit OTP sent to\n${widget.email}',
                style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 14)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => SizedBox(
                width: 48, height: 56,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true, fillColor: const Color(AppColors.surfaceDark),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(AppColors.accent), width: 2)),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                    else if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                    if (i == 5 && v.isNotEmpty) _verify();
                  },
                ),
              )),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
