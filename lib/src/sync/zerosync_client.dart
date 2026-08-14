import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zerosync_db/src/db/zerosync_database.dart';

class ZeroSyncClient {
  final ZeroSyncDatabase db;
  final String syncUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  ZeroSyncClient({
    required this.db,
    required this.syncUrl,
  });

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final uri = Uri.parse(syncUrl);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) => _onIncomingMessage(data),
        onError: (err) => disconnect(),
        onDone: () => disconnect(),
      );

      // Send initial encrypted batch sync
      await syncLocalChanges();
    } catch (_) {
      _isConnected = false;
    }
  }

  Future<void> syncLocalChanges() async {
    if (!_isConnected || _channel == null) return;

    final changes = db.getUnsyncedChanges();
    if (changes.isEmpty) return;

    final payload = jsonEncode({
      'node_id': db.nodeId,
      'changes': changes,
    });

    _channel!.sink.add(payload);
  }

  void _onIncomingMessage(dynamic rawMessage) {
    try {
      final Map<String, dynamic> msg = jsonDecode(rawMessage.toString());
      if (msg.containsKey('changes')) {
        final List list = msg['changes'];
        for (var change in list) {
          final encryptedPayload = change['encrypted_payload'];
          if (encryptedPayload != null) {
            // Decrypt on-device
            try {
              final decryptedJson = db.crypto.decrypt(encryptedPayload);
              // Decrypted payload ready for local CRDT merge
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _subscription?.cancel();
    await _channel?.sink.close();
  }
}
