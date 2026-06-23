import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class CallService {
  static RTCPeerConnection? _pc;
  static MediaStream? _localStream;
  static MediaStream? _remoteStream;

  static Function(MediaStream)? onLocalStream;
  static Function(MediaStream)? onRemoteStream;
  static Function()? onCallEnded;

  static final _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // TURN server — German server ready hone pe add karna:
      // {'urls': 'turn:YOUR_SERVER_IP:3478', 'username': 'echat', 'credential': 'PASSWORD'}
    ]
  };

  static Future<RTCSessionDescription> startCall({
    required String receiverId,
    required String callType,
  }) async {
    await _getLocalStream(callType == 'video');
    await _initPC(receiverId);
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  static Future<RTCSessionDescription> acceptCall({
    required String callerId,
    required String callType,
    required Map<String, dynamic> offerSdp,
  }) async {
    await _getLocalStream(callType == 'video');
    await _initPC(callerId);
    await _pc!.setRemoteDescription(RTCSessionDescription(offerSdp['sdp'], offerSdp['type']));
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  static Future<void> setRemoteAnswer(Map<String, dynamic> answerSdp) async {
    await _pc?.setRemoteDescription(RTCSessionDescription(answerSdp['sdp'], answerSdp['type']));
  }

  static Future<void> addIceCandidate(Map<String, dynamic> c) async {
    await _pc?.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
  }

  static Future<void> _initPC(String otherUserId) async {
    _pc = await createPeerConnection(_iceServers);
    _localStream?.getTracks().forEach((t) => _pc!.addTrack(t, _localStream!));

    _pc!.onIceCandidate = (c) => SocketService.sendIceCandidate(otherUserId, c.toMap());
    _pc!.onTrack = (e) {
      if (e.streams.isNotEmpty) {
        _remoteStream = e.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };
    _pc!.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onCallEnded?.call();
      }
    };
  }

  static Future<void> _getLocalStream(bool withVideo) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': withVideo ? {'facingMode': 'user', 'width': 640, 'height': 480} : false,
    });
    onLocalStream?.call(_localStream!);
  }

  static void toggleMute() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !t.enabled);
  }

  static void toggleCamera() {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !t.enabled);
  }

  static Future<void> switchCamera() async {
    final vt = _localStream?.getVideoTracks().firstOrNull;
    if (vt != null) await Helper.switchCamera(vt);
  }

  static void setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  static Future<void> endCall() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    await _pc?.close();
    _pc = null;
    _localStream = null;
    _remoteStream = null;
  }
}
