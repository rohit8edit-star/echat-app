import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../utils/constants.dart';
import '../chat/chat_screen.dart';
import '../contacts/contacts_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ConversationModel> _convs = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.onNewMessage = (_) => _load();
  }

  Future<void> _load() async {
    final convs = await ApiService.getConversations();
    if (mounted) setState(() { _convs = convs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: _tab == 0 ? AppBar(
        backgroundColor: const Color(AppColors.surfaceDark),
        title: const Text('E-Chat', style: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(AppColors.iconColor)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Color(AppColors.iconColor)), onPressed: () {}),
        ],
      ) : null,
      body: IndexedStack(index: _tab, children: [
        _chatList(),
        const ContactsScreen(),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(AppColors.surfaceDark),
        selectedItemColor: const Color(AppColors.accent),
        unselectedItemColor: const Color(AppColors.iconColor),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(AppColors.accent),
              onPressed: () => setState(() => _tab = 1),
              child: const Icon(Icons.chat_outlined, color: Colors.white))
          : null,
    );
  }

  Widget _chatList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(AppColors.accent)));
    if (_convs.isEmpty) return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, color: Color(AppColors.textSecondary), size: 64),
        SizedBox(height: 16),
        Text('No chats yet', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 16)),
        SizedBox(height: 8),
        Text('Start a conversation from contacts', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 13)),
      ]),
    );
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(AppColors.accent),
      child: ListView.separated(
        itemCount: _convs.length,
        separatorBuilder: (_, __) => const Divider(color: Color(AppColors.divider), height: 1, indent: 72),
        itemBuilder: (_, i) => _tile(_convs[i]),
      ),
    );
  }

  Widget _tile(ConversationModel c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(AppColors.accent),
          backgroundImage: c.displayAvatar != null
              ? NetworkImage('${AppConstants.mediaUrl}${c.displayAvatar}') : null,
          child: c.displayAvatar == null
              ? Text(c.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20)) : null,
        ),
        if (c.isOnline) Positioned(right: 0, bottom: 0,
          child: Container(width: 13, height: 13,
            decoration: BoxDecoration(color: const Color(AppColors.online), shape: BoxShape.circle,
                border: Border.all(color: const Color(AppColors.backgroundDark), width: 2)))),
      ]),
      title: Text(c.displayName,
          style: const TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(c.lastMessage ?? 'No messages yet',
          style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (c.lastMessageTime != null)
          Text(timeago.format(c.lastMessageTime!, locale: 'en_short'),
              style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 11)),
        const SizedBox(height: 4),
        if (c.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(AppColors.unreadBadge), borderRadius: BorderRadius.circular(10)),
            child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
      ]),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: c))).then((_) => _load()),
    );
  }
}
