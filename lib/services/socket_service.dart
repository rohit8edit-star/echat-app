import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';
import '../models/models.dart';

class SocketService {
  static IO.Socket? _socket;

  // Message callbacks
  static Function(MessageModel)? onNewMessage;
  static Function(String)? onMessageDeleted;
  static Function(String, String, String)? onMessageStatus;
  static Function(String, bool)? onTyping;
  static Function(String)? onUserOnline;
  static Function(String, DateTime?)? onUserOffline;

  // Call callbacks
  static Function(Map<String, dynamic>)? onIncomingCall;
  static Function(String)? onCallRinging;
  static Function(String, Map<String, dynamic>)? onCallAnswered;
  static Function(String)? onCallRejected;
  static Function(String)? onCallMissed;
  static Function(String, int)? onCallEnded;
  static Function(Map<String, dynamic>)? onIceCandidate;

  static void connect(String token) {
    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      _socket!.emit('join_rooms');
    });

    _socket!.on('new_message', (d) =>
        onNewMessage?.call(MessageModel.fromJson(Map<String, dynamic>.from(d))));
    _socket!.on('message_deleted', (d) => onMessageDeleted?.call(d['message_id']));
    _socket!.on('message_status_update', (d) =>
        onMessageStatus?.call(d['message_id'], d['status'], d['user_id']));
    _socket!.on('typing', (d) => onTyping?.call(d['user_id'], d['isTyping']));
    _socket!.on('user_online', (d) => onUserOnline?.call(d['userId']));
    _socket!.on('user_offline', (d) {
      final ls = d['last_seen'] != null ? DateTime.parse(d['last_seen']) : null;
      onUserOffline?.call(d['userId'], ls);
    });

    // Calls
    _socket!.on('incoming_call', (d) =>
        onIncomingCall?.call(Map<String, dynamic>.from(d)));
    _socket!.on('call_ringing', (d) => onCallRinging?.call(d['call_id']));
    _socket!.on('call_answered', (d) =>
        onCallAnswered?.call(d['call_id'], Map<String, dynamic>.from(d['answer'])));
    _socket!.on('call_rejected', (d) => onCallRejected?.call(d['call_id']));
    _socket!.on('call_missed', (d) => onCallMissed?.call(d['call_id']));
    _socket!.on('call_ended', (d) => onCallEnded?.call(d['call_id'], d['duration'] ?? 0));
    _socket!.on('ice_candidate', (d) =>
        onIceCandidate?.call(Map<String, dynamic>.from(d['candidate'])));

    _socket!.onDisconnect((_) => print('Socket disconnected'));
    _socket!.onError((e) => print('Socket error: $e'));
  }

  // Messages
  static void joinConversation(String id) =>
      _socket?.emit('join_conversation', {'conversation_id': id});

  static void sendMessage({
    required String conversationId,
    required String type,
    String? content,
    String? mediaUrl,
    String? replyTo,
  }) =>
      _socket?.emit('send_message', {
        'conversation_id': conversationId,
        'type': type,
        'content': content,
        'media_url': mediaUrl,
        'reply_to': replyTo,
      });

  static void deleteMessage(String msgId, String convId) =>
      _socket?.emit('delete_message', {'message_id': msgId, 'conversation_id': convId});

  static void sendTyping(String convId, bool isTyping) =>
      _socket?.emit('typing', {'conversation_id': convId, 'isTyping': isTyping});

  static void updateMessageStatus(String msgId, String status) =>
      _socket?.emit('message_status', {'message_id': msgId, 'status': status});

  // Calls
  static void callUser({required String receiverId, required String callType, required Map<String, dynamic> offer}) =>
      _socket?.emit('call_user', {'receiver_id': receiverId, 'call_type': callType, 'offer': offer});

  static void acceptCall({required String callId, required String callerId, required Map<String, dynamic> answer}) =>
      _socket?.emit('call_accepted', {'call_id': callId, 'caller_id': callerId, 'answer': answer});

  static void rejectCall({required String callId, required String callerId}) =>
      _socket?.emit('call_rejected', {'call_id': callId, 'caller_id': callerId});

  static void endCall({required String callId, required String otherUserId}) =>
      _socket?.emit('call_ended', {'call_id': callId, 'other_user_id': otherUserId});

  static void sendIceCandidate(String otherUserId, Map<String, dynamic> candidate) =>
      _socket?.emit('ice_candidate', {'other_user_id': otherUserId, 'candidate': candidate});

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static bool get isConnected => _socket?.connected ?? false;
}
