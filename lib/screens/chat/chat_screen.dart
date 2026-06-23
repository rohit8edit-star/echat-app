import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart';
import '../../utils/constants.dart';
import '../../widgets/message_bubble.dart';
import '../call/call_screen.dart';
import '../call/incoming_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl  = TextEditingController();
  final _scroll   = ScrollController();
  List<MessageModel> _msgs = [];
  bool _loading = true, _typing = false, _otherTyping = false;
  MessageModel? _replyTo;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = context.read<AuthProvider>().user?.id;
    _loadMessages();
    SocketService.joinConversation(widget.conversation.id);

    SocketService.onNewMessage = (msg) {
      if (msg.conversationId == widget.conversation.id && mounted) {
        setState(() => _msgs.add(msg));
        _scrollBottom();
        SocketService.updateMessageStatus(msg.id, 'read');
      }
    };
    SocketService.onMessageDeleted = (id) {
      if (!mounted) return;
      setState(() {
        final i = _msgs.indexWhere((m) => m.id == id);
        if (i >= 0) _msgs[i] = MessageModel(id: id, conversationId: widget.conversation.id,
            senderId: _msgs[i].senderId, type: 'text', isDeleted: true, createdAt: _msgs[i].createdAt);
      });
    };
    SocketService.onTyping = (uid, t) {
      if (uid != _myId && mounted) setState(() => _otherTyping = t);
    };
    SocketService.onMessageStatus = (id, status, uid) {
      if (!mounted) return;
      setState(() { final i = _msgs.indexWhere((m) => m.id == id); if (i >= 0) _msgs[i].status = status; });
    };
    SocketService.onIncomingCall = (data) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingCallScreen(
        callId: data['call_id'], callerId: data['caller_id'],
        callerName: data['caller_name'] ?? 'Unknown', callerAvatar: data['caller_avatar'],
        callType: data['call_type'], offerSdp: Map<String, dynamic>.from(data['offer']),
      )));
    };
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(widget.conversation.id);
      if (mounted) {
        setState(() { _msgs = msgs; _loading = false; });
        _scrollBottom();
        for (final m in msgs) if (m.senderId != _myId) SocketService.updateMessageStatus(m.id, 'read');
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  void _send() {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    SocketService.sendMessage(conversationId: widget.conversation.id, type: 'text', content: t, replyTo: _replyTo?.id);
    _msgCtrl.clear();
    setState(() => _replyTo = null);
    _setTyping(false);
  }

  void _setTyping(bool v) {
    if (_typing != v) { _typing = v; SocketService.sendTyping(widget.conversation.id, v); }
  }

  Future<void> _startCall(String callType) async {
    try {
      final offer = await CallService.startCall(receiverId: widget.conversation.otherUserId!, callType: callType);
      SocketService.callUser(receiverId: widget.conversation.otherUserId!, callType: callType, offer: offer.toMap());
      SocketService.onCallRinging = (callId) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(
          callId: callId, otherUserId: widget.conversation.otherUserId!,
          otherUserName: widget.conversation.displayName, otherUserAvatar: widget.conversation.displayAvatar,
          callType: callType, isOutgoing: true,
        )));
      };
    } catch (_) { _snack('Could not start call'); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    _msgCtrl.dispose(); _scroll.dispose();
    SocketService.onNewMessage = null; SocketService.onTyping = null;
    SocketService.onIncomingCall = null; SocketService.onCallRinging = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surfaceDark),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(AppColors.textPrimary)), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: const Color(AppColors.accent),
            backgroundImage: c.displayAvatar != null ? NetworkImage('${AppConstants.mediaUrl}${c.displayAvatar}') : null,
            child: c.displayAvatar == null ? Text(c.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white)) : null),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.displayName, style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 16, fontWeight: FontWeight.w600)),
            Text(c.isOnline ? 'online' : c.lastSeen != null ? 'last seen ${timeago.format(c.lastSeen!)}' : '',
                style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 12)),
          ]),
        ]),
        actions: [
          if (c.type == 'private') ...[
            IconButton(icon: const Icon(Icons.call_outlined, color: Color(AppColors.iconColor)), onPressed: () => _startCall('voice')),
            IconButton(icon: const Icon(Icons.videocam_outlined, color: Color(AppColors.iconColor)), onPressed: () => _startCall('video')),
          ],
          IconButton(icon: const Icon(Icons.more_vert, color: Color(AppColors.iconColor)), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(AppColors.accent)))
            : _msgs.isEmpty
                ? const Center(child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: Color(AppColors.textSecondary))))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i]; final isMe = m.senderId == _myId;
                      return MessageBubble(message: m, isMe: isMe,
                        onReply: () => setState(() => _replyTo = m),
                        onDelete: isMe ? () => SocketService.deleteMessage(m.id, widget.conversation.id) : null);
                    })),
        if (_otherTyping) Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('${c.displayName} is typing...', style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 12)))),
        if (_replyTo != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(AppColors.surfaceDark),
          child: Row(children: [
            Container(width: 3, height: 40, color: const Color(AppColors.accent)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Replying to', style: TextStyle(color: Color(AppColors.accent), fontSize: 12, fontWeight: FontWeight.bold)),
              Text(_replyTo?.content ?? '', style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Color(AppColors.iconColor), size: 18),
                onPressed: () => setState(() => _replyTo = null)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: const Color(AppColors.surfaceDark),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: const Color(AppColors.cardDark), borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                const SizedBox(width: 4),
                Expanded(child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Color(AppColors.textPrimary)),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Message', hintStyle: TextStyle(color: Color(AppColors.textSecondary)),
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                  onChanged: (v) => _setTyping(v.isNotEmpty),
                )),
                IconButton(icon: const Icon(Icons.attach_file, color: Color(AppColors.iconColor)), onPressed: () {}),
              ]),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(width: 48, height: 48,
                decoration: const BoxDecoration(color: Color(AppColors.accent), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22)),
            ),
          ]),
        ),
      ]),
    );
  }
}
