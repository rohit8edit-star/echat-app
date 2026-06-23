import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surfaceDark),
        title: const Text('Profile', style: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 30),
          Center(child: Stack(children: [
            CircleAvatar(radius: 50, backgroundColor: const Color(AppColors.accent),
              backgroundImage: user.avatar != null ? NetworkImage('${AppConstants.mediaUrl}${user.avatar}') : null,
              child: user.avatar == null ? Text(user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 36)) : null),
            Positioned(right: 0, bottom: 0, child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(AppColors.accent), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
          ])),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('@${user.username}', style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 14)),
          const SizedBox(height: 24),
          _section([
            _info(Icons.phone_outlined, 'Phone', user.phone),
            _info(Icons.email_outlined, 'Email', user.email),
          ]),
          const SizedBox(height: 16),
          _section([
            _action(context, Icons.edit_outlined, 'Edit Profile', () => _editProfile(context, user.name, user.username)),
            _action(context, Icons.lock_outline, 'Change Password', () => _changePw(context)),
            _action(context, Icons.block_outlined, 'Blocked Users', () {}),
          ]),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16))))),
          const SizedBox(height: 24),
          const Text('E-Chat v1.0.0 by EasyToShort', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 12)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  static Widget _section(List<Widget> c) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: const Color(AppColors.surfaceDark), borderRadius: BorderRadius.circular(14)),
    child: Column(children: c));

  static Widget _info(IconData icon, String label, String val) => ListTile(
    leading: Icon(icon, color: const Color(AppColors.accent)),
    title: Text(label, style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 12)),
    subtitle: Text(val, style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 15)));

  static Widget _action(BuildContext ctx, IconData icon, String title, VoidCallback fn) => ListTile(
    leading: Icon(icon, color: const Color(AppColors.iconColor)),
    title: Text(title, style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 15)),
    trailing: const Icon(Icons.chevron_right, color: Color(AppColors.iconColor)),
    onTap: fn);

  void _editProfile(BuildContext context, String name, String username) {
    final nc = TextEditingController(text: name);
    final uc = TextEditingController(text: username);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(AppColors.surfaceDark),
      title: const Text('Edit Profile', style: TextStyle(color: Color(AppColors.textPrimary))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nc, style: const TextStyle(color: Color(AppColors.textPrimary)),
            decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(AppColors.textSecondary)))),
        TextField(controller: uc, style: const TextStyle(color: Color(AppColors.textPrimary)),
            decoration: const InputDecoration(labelText: 'Username', labelStyle: TextStyle(color: Color(AppColors.textSecondary)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(AppColors.textSecondary)))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await ApiService.updateProfile(name: nc.text.trim(), username: uc.text.trim());
          final u = await ApiService.getProfile();
          if (u != null && context.mounted) context.read<AuthProvider>().setUser(u);
        }, child: const Text('Save', style: TextStyle(color: Color(AppColors.accent)))),
      ]));
  }

  void _changePw(BuildContext context) {
    final oc = TextEditingController(), nc = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(AppColors.surfaceDark),
      title: const Text('Change Password', style: TextStyle(color: Color(AppColors.textPrimary))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: oc, obscureText: true, style: const TextStyle(color: Color(AppColors.textPrimary)),
            decoration: const InputDecoration(labelText: 'Current Password', labelStyle: TextStyle(color: Color(AppColors.textSecondary)))),
        TextField(controller: nc, obscureText: true, style: const TextStyle(color: Color(AppColors.textPrimary)),
            decoration: const InputDecoration(labelText: 'New Password', labelStyle: TextStyle(color: Color(AppColors.textSecondary)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(AppColors.textSecondary)))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          final res = await ApiService.changePassword(oc.text, nc.text);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
        }, child: const Text('Change', style: TextStyle(color: Color(AppColors.accent)))),
      ]));
  }

  void _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}
