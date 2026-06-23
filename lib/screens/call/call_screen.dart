import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/call_service.dart';
import '../../services/socket_service.dart';
import '../../utils/constants.dart';

class CallScreen extends StatefulWidget {
  final String callId, otherUserId, otherUserName, callType;
  final String? otherUserAvatar;
  final bool isOutgoing;

  const CallScreen({
    super.key, required this.callId, required this.otherUserId,
    required this.otherUserName, required this.callType,
    this.otherUserAvatar, required this.isOutgoing,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _local  = RTCVideoRenderer();
  final _remote = RTCVideoRenderer();
  bool _muted = false, _camOff = false, _speaker = true, _connected = false;
  String _status = 'Connecting...';
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _local.initialize();
    _remote.initialize();

    CallService.onLocalStream  = (s) { if (mounted) setState(() => _local.srcObject = s); };
    CallService.onRemoteStream = (s) { if (mounted) setState(() { _remote.srcObject = s; _connected = true; _status = 'Connected'; _timer(); }); };
    CallService.onCallEnded    = () { if (mounted) _end(); };

    SocketService.onIceCandidate  = (c) => CallService.addIceCandidate(c);
    SocketService.onCallAnswered  = (id, ans) { if (id == widget.callId) { CallService.setRemoteAnswer(ans); if (mounted) setState(() => _status = 'Connected'); } };
    SocketService.onCallRejected  = (id) { if (id == widget.callId && mounted) { setState(() => _status = 'Call Declined'); Future.delayed(const Duration(seconds: 2), _end); } };
  }

  void _timer() => Future.doWhile(() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !_connected) return false;
    setState(() => _duration++);
    return true;
  });

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _end() async {
    SocketService.endCall(callId: widget.callId, otherUserId: widget.otherUserId);
    await CallService.endCall();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _local.dispose(); _remote.dispose();
    SocketService.onIceCandidate = null; SocketService.onCallAnswered = null; SocketService.onCallRejected = null;
    CallService.onLocalStream = null; CallService.onRemoteStream = null; CallService.onCallEnded = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: widget.callType == 'video' ? _video() : _voice(),
  );

  Widget _video() => Stack(children: [
    Positioned.fill(child: RTCVideoView(_remote, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
    Positioned(top: 50, right: 16, width: 100, height: 140,
      child: ClipRRect(borderRadius: BorderRadius.circular(12),
        child: RTCVideoView(_local, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))),
    Positioned(top: 0, left: 0, right: 0, child: SafeArea(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(_connected ? _fmt(_duration) : _status, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ])))),
    Positioned(bottom: 0, left: 0, right: 0, child: _controls(true)),
  ]);

  Widget _voice() => SafeArea(child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Padding(padding: const EdgeInsets.only(top: 60), child: Column(children: [
        CircleAvatar(radius: 60, backgroundColor: const Color(AppColors.accent),
          backgroundImage: widget.otherUserAvatar != null ? NetworkImage('${AppConstants.mediaUrl}${widget.otherUserAvatar}') : null,
          child: widget.otherUserAvatar == null ? Text(widget.otherUserName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 42)) : null),
        const SizedBox(height: 20),
        Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_connected ? _fmt(_duration) : _status, style: const TextStyle(color: Colors.white54, fontSize: 16)),
      ])),
      _controls(false),
    ],
  ));

  Widget _controls(bool isVideo) => Container(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.black87, Colors.transparent])),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _btn(icon: _muted ? Icons.mic_off : Icons.mic, label: _muted ? 'Unmute' : 'Mute',
            active: _muted, onTap: () { CallService.toggleMute(); setState(() => _muted = !_muted); }),
        if (isVideo) _btn(icon: _camOff ? Icons.videocam_off : Icons.videocam, label: _camOff ? 'Cam Off' : 'Cam On',
            active: _camOff, onTap: () { CallService.toggleCamera(); setState(() => _camOff = !_camOff); })
        else _btn(icon: _speaker ? Icons.volume_up : Icons.volume_off, label: 'Speaker',
            active: _speaker, onTap: () { CallService.setSpeaker(!_speaker); setState(() => _speaker = !_speaker); }),
        if (isVideo) _btn(icon: Icons.flip_camera_android, label: 'Flip', onTap: CallService.switchCamera),
      ]),
      const SizedBox(height: 24),
      GestureDetector(onTap: _end, child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)]),
        child: const Icon(Icons.call_end, color: Colors.white, size: 32))),
    ]),
  );

  Widget _btn({required IconData icon, required String label, required VoidCallback onTap, bool active = false}) =>
    GestureDetector(onTap: onTap, child: Column(children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(color: active ? const Color(AppColors.accent) : Colors.white.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 26)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]));
}
