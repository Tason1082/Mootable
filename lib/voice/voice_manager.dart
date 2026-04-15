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

  // ================= EVENTS =================
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

    signalR.onOffer = (r, offer, userId) async {
      userId = normalize(userId);
      if (userId == myUserId) return;

      if (!webrtc.hasPeer(userId)) {
        await webrtc.createPeer(userId, polite: true);
      }

      await webrtc.handleOffer(userId, offer);
    };

    signalR.onAnswer = (r, answer, userId) async {
      userId = normalize(userId);
      if (userId == myUserId) return;

      await webrtc.handleAnswer(userId, answer);
    };

    signalR.onIce = (r, c, userId, mid, index) async {
      userId = normalize(userId);
      if (userId == myUserId) return;

      if (!webrtc.hasPeer(userId)) {
        await webrtc.createPeer(userId, polite: false);
      }

      await webrtc.addIce(userId, c, mid, index);
    };

    signalR.onUserJoined = (id) async {
      final user = normalize(id.toString());

      if (!members.value.contains(user)) {
        members.value = [...members.value, user];
      }

      if (!webrtc.hasPeer(user)) {
        await webrtc.createPeer(user, polite: false);

        if (_shouldSendOffer(user)) {
          final offer = await webrtc.createOffer(user);
          signalR.sendOffer(roomId.toString(), offer);
        }
      }
    };

    signalR.onUserLeft = (id) {
      final user = normalize(id);

      members.value =
          members.value.where((m) => m != user).toList();

      webrtc.removePeer(user);
    };
    signalR.onRoomDeleted = (roomId) async {
      final id = int.tryParse(roomId.toString());

      if (id != this.roomId) return;

      // 🔥 tüm bağlantıları kapat
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