class UserModel {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String email;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        name: j['name'],
        username: j['username'],
        phone: j['phone'],
        email: j['email'],
        avatar: j['avatar'],
        isOnline: j['is_online'] == 1 || j['is_online'] == true,
        lastSeen: j['last_seen'] != null ? DateTime.parse(j['last_seen']) : null,
      );
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final MessageModel? replyTo;
  final bool isDeleted;
  final DateTime createdAt;
  String status;
  final String? senderName;
  final String? senderAvatar;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.replyTo,
    this.isDeleted = false,
    required this.createdAt,
    this.status = 'sent',
    this.senderName,
    this.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'],
        conversationId: j['conversation_id'],
        senderId: j['sender_id'],
        type: j['type'] ?? 'text',
        content: j['content'],
        mediaUrl: j['media_url'],
        replyTo: j['reply_to'] != null
            ? MessageModel.fromJson(Map<String, dynamic>.from(j['reply_to']))
            : null,
        isDeleted: j['is_deleted'] == 1 || j['is_deleted'] == true,
        createdAt: DateTime.parse(j['created_at']),
        status: j['status'] ?? 'sent',
        senderName: j['sender_name'],
        senderAvatar: j['sender_avatar'],
      );
}

class ConversationModel {
  final String id;
  final String type;
  final String? name;
  final String? avatar;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool isOnline;
  final DateTime? lastSeen;
  int unreadCount;

  ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.isOnline = false,
    this.lastSeen,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) => ConversationModel(
        id: j['id'],
        type: j['type'] ?? 'private',
        name: j['name'] ?? j['other_user_name'],
        avatar: j['avatar'] ?? j['other_user_avatar'],
        lastMessage: j['last_message'],
        lastMessageType: j['last_message_type'],
        lastMessageTime: j['last_message_time'] != null
            ? DateTime.parse(j['last_message_time'])
            : null,
        otherUserId: j['other_user_id'],
        otherUserName: j['other_user_name'],
        otherUserAvatar: j['other_user_avatar'],
        isOnline: j['is_online'] == 1 || j['is_online'] == true,
        lastSeen: j['last_seen'] != null ? DateTime.parse(j['last_seen']) : null,
      );

  String get displayName =>
      type == 'group' ? (name ?? 'Group') : (otherUserName ?? 'Unknown');
  String? get displayAvatar =>
      type == 'group' ? avatar : otherUserAvatar;
}
