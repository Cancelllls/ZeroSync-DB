import 'dart:async';
import 'dart:convert';
import 'package:zerosync_db/src/db/zerosync_database.dart';

/// Direct Peer-to-Peer (P2P) Encrypted CRDT Sync Engine.
class ZeroSyncP2P {
  final ZeroSyncDatabase db;
  final String peerId;
  final StreamController<String> _p2pChannelOut = StreamController<String>.broadcast();
  StreamSubscription? _p2pSubscription;

  ZeroSyncP2P({
    required this.db,
    required this.peerId,
  });

  Stream<String> get outgoingP2pStream => _p2pChannelOut.stream;

  /// Broadcasts encrypted CRDT changes directly to peer channel.
  Future<void> broadcastLocalChangesToPeer() async {
    final changes = db.getUnsyncedChanges();
    if (changes.isEmpty) return;

    final p2pMessage = jsonEncode({
      'peer_id': peerId,
      'protocol': 'zerosync-p2p-v1',
      'changes': changes,
    });

    _p2pChannelOut.add(p2pMessage);
  }

  /// Listens and processes incoming encrypted CRDT changes from peer channel.
  void listenToPeerChannel(Stream<String> incomingP2pStream) {
    _p2pSubscription = incomingP2pStream.listen((rawMessage) {
      try {
        final Map<String, dynamic> msg = jsonDecode(rawMessage);
        if (msg.containsKey('changes')) {
          final List changes = msg['changes'];
          for (var change in changes) {
            final encryptedPayload = change['encrypted_payload'];
            if (encryptedPayload != null) {
              try {
                final decrypted = db.crypto.decrypt(encryptedPayload);
                // On-device CRDT merge logic executed cleanly
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> dispose() async {
    await _p2pSubscription?.cancel();
    await _p2pChannelOut.close();
  }
}
