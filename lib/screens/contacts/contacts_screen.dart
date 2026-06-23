import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../chat/chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<UserModel> _all = [], _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final c = await ApiService.getContacts();
    if (mounted) setState(() { _all = c; _filtered = c; _loading = false; });
  }

  void _filter(String q) => setState(() =>
      _filtered = _all.where((c) => c.name.toLowerCase().contains(q.toLowerCase()) || c.phone.contains(q)).toList());

  Future<void> _addContact() async {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(AppColors.surfaceDark),
      title: const Text('Add Contact', style: TextStyle(color: Color(AppColors.textPrimary))),
      content: TextField(controller: ctrl, keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(AppColors.textPrimary)),
          decoration: const InputDecoration(hintText: 'Phone number', hintStyle: TextStyle(color: Color(AppColors.textSecondary)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(AppColors.textSecondary)))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          final res = await ApiService.searchUser(ctrl.text.trim());
          if (!mounted) return;
          if (res['success']) {
            final user = UserModel.fromJson(res['user']);
            final add = await ApiService.addContact(user.id);
            if (add['success'] && mounted) { _snack('Contact added!'); _load(); }
          } else _snack(res['message'] ?? 'Not found');
        }, child: const Text('Add', style: TextStyle(color: Color(AppColors.accent)))),
      ],
    ));
  }

  Future<void> _chat(UserModel u) async {
    final id = await ApiService.getOrCreateConversation(u.id);
    if (id != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        conversation: ConversationModel(id: id, type: 'private',
            otherUserId: u.id, otherUserName: u.name, otherUserAvatar: u.avatar,
            isOnline: u.isOnline, lastSeen: u.lastSeen))));
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surfaceDark),
        title: const Text('Contacts', style: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.person_add_outlined, color: Color(AppColors.iconColor)), onPressed: _addContact)],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12),
          child: TextField(controller: _search, onChanged: _filter,
            style: const TextStyle(color: Color(AppColors.textPrimary)),
            decoration: InputDecoration(
              hintText: 'Search contacts...', hintStyle: const TextStyle(color: Color(AppColors.textSecondary)),
              prefixIcon: const Icon(Icons.search, color: Color(AppColors.iconColor)),
              filled: true, fillColor: const Color(AppColors.surfaceDark),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: Color(AppColors.accent))))
        else if (_filtered.isEmpty) const Expanded(child: Center(
            child: Text('No contacts', style: TextStyle(color: Color(AppColors.textSecondary)))))
        else Expanded(child: ListView.builder(
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final u = _filtered[i];
            return ListTile(
              leading: Stack(children: [
                CircleAvatar(radius: 24, backgroundColor: const Color(AppColors.accent),
                    child: Text(u.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18))),
                if (u.isOnline) Positioned(right: 0, bottom: 0,
                  child: Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: const Color(AppColors.online), shape: BoxShape.circle,
                        border: Border.all(color: const Color(AppColors.backgroundDark), width: 2)))),
              ]),
              title: Text(u.name, style: const TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.w500)),
              subtitle: Text(u.phone, style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 13)),
              trailing: const Icon(Icons.chat_bubble_outline, color: Color(AppColors.iconColor), size: 20),
              onTap: () => _chat(u),
            );
          })),
      ]),
    );
  }
}
