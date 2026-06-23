import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart';
import '../../utils/constants.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId, callerId, callerName, callType;
  final String? callerAvatar;
  final Map<String, dynamic> offerSdp;

  const IncomingCallScreen({
    super.key, required this.callId, required this.callerId,
    required this.callerName, required this.callType,
    this.callerAvatar, required this.offerSdp,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _anim  = Tween<double>(begin: 0.93, end: 1.07).animate(_pulse);
    SocketService.onCallMissed = (id) { if (id == widget.callId && mounted) Navigator.pop(context); };
  }

  @override
  void dispose() { _pulse.dispose(); SocketService.onCallMissed = null; super.dispose(); }

  Future<void> _accept() async {
    try {
      final answer = await CallService.acceptCall(
          callerId: widget.callerId, callType: widget.callType, offerSdp: widget.offerSdp);
      SocketService.acceptCall(callId: widget.callId, callerId: widget.callerId, answer: answer.toMap());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CallScreen(
        callId: widget.callId, otherUserId: widget.callerId,
        otherUserName: widget.callerName, otherUserAvatar: widget.callerAvatar,
        callType: widget.callType, isOutgoing: false)));
    } catch (_) { _snack('Failed to accept call'); }
  }

  void _reject() {
    SocketService.rejectCall(callId: widget.callId, callerId: widget.callerId);
    Navigator.pop(context);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(padding: const EdgeInsets.only(top: 60), child: Column(children: [
            Text(widget.callType == 'video' ? 'Incoming Video Call' : 'Incoming Voice Call',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 30),
            ScaleTransition(scale: _anim, child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(AppColors.accent),
                boxShadow: [BoxShadow(color: const Color(AppColors.accent).withOpacity(0.4), blurRadius: 30, spreadRadius: 10)]),
              child: widget.callerAvatar != null
                  ? ClipOval(child: Image.network('${AppConstants.mediaUrl}${widget.callerAvatar}', fit: BoxFit.cover))
                  : Center(child: Text(widget.callerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
            )),
            const SizedBox(height: 24),
            Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('is calling you...', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ])),
          Padding(padding: const EdgeInsets.only(bottom: 60),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _btn(Icons.call_end, Colors.red, 'Decline', _reject),
              _btn(widget.callType == 'video' ? Icons.videocam : Icons.call, Colors.green, 'Accept', _accept),
            ])),
        ],
      )),
    );
  }

  Widget _btn(IconData icon, Color color, String label, VoidCallback fn) => Column(children: [
    GestureDetector(onTap: fn, child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)]),
      child: Icon(icon, color: Colors.white, size: 32))),
    const SizedBox(height: 12),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
  ]);
}
