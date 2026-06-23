import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const MessageBubble({super.key, required this.message, required this.isMe, this.onReply, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _deleted();
    return GestureDetector(
      onLongPress: () => _options(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(top: 2, bottom: 2, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? const Color(AppColors.bubbleSent) : const Color(AppColors.bubbleReceived),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) _replyPreview(),
              if (message.type == 'text')
                Text(message.content ?? '', style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 15))
              else if (message.type == 'image')
                ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network('${AppConstants.mediaUrl}${message.mediaUrl}', width: 200, fit: BoxFit.cover))
              else
                Text('[${message.type}]', style: const TextStyle(color: Color(AppColors.textSecondary))),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat('HH:mm').format(message.createdAt),
                    style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 11)),
                if (isMe) ...[const SizedBox(width: 4), _tick()],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replyPreview() => Container(
    padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(AppColors.accent), width: 3))),
    child: Text(message.replyTo?.content ?? '',
        style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  Widget _deleted() => Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(AppColors.surfaceDark), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(AppColors.divider))),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.block, color: Color(AppColors.textSecondary), size: 14),
        SizedBox(width: 4),
        Text('This message was deleted',
            style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 13, fontStyle: FontStyle.italic)),
      ]),
    ),
  );

  Widget _tick() {
    switch (message.status) {
      case 'read':      return const Icon(Icons.done_all, color: Color(AppColors.accent), size: 14);
      case 'delivered': return const Icon(Icons.done_all, color: Color(AppColors.textSecondary), size: 14);
      case 'sent':      return const Icon(Icons.check, color: Color(AppColors.textSecondary), size: 14);
      default:          return const Icon(Icons.access_time, color: Color(AppColors.textSecondary), size: 14);
    }
  }

  void _options(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(AppColors.surfaceDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.reply, color: Color(AppColors.textPrimary)),
          title: const Text('Reply', style: TextStyle(color: Color(AppColors.textPrimary))),
          onTap: () { Navigator.pop(context); onReply?.call(); },
        ),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(context); onDelete?.call(); },
          ),
      ]),
    );
  }
}
