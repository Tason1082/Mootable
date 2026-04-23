import 'dart:async';
import 'package:flutter/foundation.dart';

import 'voice_signalr.dart';
import 'webrtc_voice_service.dart';

class VoiceManager {
  static final VoiceManager _instance = VoiceManager._internal();
  factory VoiceManager() => _instance;
  VoiceManager._internal();

  final WebRTCVoiceService webrtc = WebRTCVoiceService();
  final VoiceSignalR signalR = VoiceSignalR();

  final ValueNotifier<List<String>> members = ValueNotifier([]);
  final ValueNotifier<bool> micOn = ValueNotifier(true);
  final ValueNotifier<bool> connected = ValueNotifier(false);

  String? myUserId;
  int? roomId;

  bool initialized = false;

  String normalize(String v) => v.trim().toLowerCase();

  // ================= INIT =================
  Future<void> init({
    required int roomId,
    required String userId,
    required List<String> initialMembers,
  }) async {
    if (initialized) return;

    this.roomId = roomId;
    myUserId = normalize(userId);
    members.value = initialMembers.map(normalize).toList();

    await webrtc.init();
    await signalR.connect();

    _setupEvents();

    await signalR.joinRoom(roomId.toString());

    connected.value = true;
    initialized = true;

    _connectToExistingUsers();
  }

  void _setupEvents() {
    webrtc.onAnswerCreated = (userId, sdp) {
      signalR.sendAnswer(roomId.toString(), sdp);
    };

    webrtc.onIceCandidate = (userId, c, mid, index) {
      signalR.sendIce(roomId.toString(), c, mid, index);
    };

    webrtc.onRemoteStream = (userId, stream) {
      for (var t in stream.getAudioTracks()) {
        t.enabled = true;
      }
    };

    // ================= OFFER =================
    signalR.onOffer = (r, offer, connId) async {
      final id = connId.toString();

      if (!webrtc.hasPeer(id)) {
        await webrtc.createPeer(id, polite: true);
      }

      await webrtc.handleOffer(id, offer);
    };

    // ================= ANSWER =================
    signalR.onAnswer = (r, answer, connId) async {
      final id = connId.toString();

      if (!webrtc.hasPeer(id)) {
        await webrtc.createPeer(id, polite: false);
      }

      await webrtc.handleAnswer(id, answer);
    };

    // ================= ICE =================
    signalR.onIce = (r, c, connId, mid, index) async {
      final id = connId.toString();

      if (!webrtc.hasPeer(id)) {
        await webrtc.createPeer(id, polite: false);
      }

      await webrtc.addIce(id, c, mid, index);
    };

    // ================= PEER JOINED =================
    signalR.onPeerJoined = (id) async {
      final connId = id.toString();

      if (!webrtc.hasPeer(connId)) {
        await webrtc.createPeer(connId, polite: false);

        if (_shouldSendOffer(connId)) {
          final offer = await webrtc.createOffer(connId);
          signalR.sendOffer(roomId.toString(), offer);
        }
      }
    };

    // ================= USER JOINED (UI ONLY) =================
    signalR.onUserJoined = (id) {
      final userId = id.toString();

      if (!members.value.contains(userId)) {
        members.value = [...members.value, userId];
      }
    };

    // ================= USER LEFT =================
    signalR.onUserLeft = (id) {
      final connId = id.toString();

      members.value =
          members.value.where((m) => m != connId).toList();

      webrtc.removePeer(connId);
    };

    // ================= ROOM DELETED =================
    signalR.onRoomDeleted = (roomId) async {
      final id = int.tryParse(roomId.toString());
      if (id != this.roomId) return;

      await leave();
    };
  }

  // ================= LOGIC =================
  bool _shouldSendOffer(String other) {
    return myUserId!.compareTo(other) < 0;
  }

  Future<void> _connectToExistingUsers() async {
    for (var user in members.value) {
      if (user == myUserId) continue;

      if (_shouldSendOffer(user)) {
        await webrtc.createPeer(user, polite: false);
        final offer = await webrtc.createOffer(user);
        signalR.sendOffer(roomId.toString(), offer);
      }
    }
  }

  // ================= ACTIONS =================
  void toggleMic() {
    micOn.value = !micOn.value;
    webrtc.toggleMic(micOn.value);
  }

  Future<void> leave() async {
    await signalR.disconnect();
    await webrtc.dispose();

    members.value = [];
    connected.value = false;
    initialized = false;
  }
}