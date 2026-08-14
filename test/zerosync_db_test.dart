import 'dart:io';
import 'package:test/test.dart';
import 'package:zerosync_db/zerosync_db.dart';

void main() {
  group('ZeroSync-DB Advanced Feature Tests', () {
    final testDbPath = 'test_zerosync_adv.db';

    tearDown(() {
      final f = File(testDbPath);
      if (f.existsSync()) f.deleteSync();
    });

    test('ZeroCrypto AES-256-GCM Encryption & Decryption', () {
      final crypto = ZeroCrypto('my-super-secret-key-12345');
      final original = 'Hello ZeroSync-DB! Top Secret Data';

      final ciphertext = crypto.encrypt(original);
      expect(ciphertext, isNot(equals(original)));

      final decrypted = crypto.decrypt(ciphertext);
      expect(decrypted, equals(original));
    });

    test('ZeroSearch Blind Indexing Token Generation', () {
      final search = ZeroSearch('user-passphrase-secret');
      final token1 = search.generateBlindToken('confidential');
      final token2 = search.generateBlindToken('confidential');
      final token3 = search.generateBlindToken('public');

      expect(token1, equals(token2));
      expect(token1, isNot(equals(token3)));

      final textTokens = search.generateBlindTokensForText('Confidential document payload');
      expect(textTokens.length, greaterThanOrEqualTo(2));
    });

    test('ZeroVault Multi-User Key Share Tokens', () {
      final vault = ZeroVault.create('vault_001', 'vault-secret-key-999');
      final recipientPubkey = 'pubkey_ed25519_user_b';

      final shareToken = vault.createShareToken(recipientPubkey);
      expect(shareToken, isNotEmpty);

      final decryptedData = ZeroVault.decryptShareToken(shareToken, 'vault-secret-key-999');
      expect(decryptedData['vault_id'], equals('vault_001'));
    });

    test('ZeroSyncP2P Channel Communication', () async {
      final db = await ZeroSyncDatabase.open(
        path: testDbPath,
        secretKey: 'passphrase-secret',
        nodeId: 'peer_node_a',
      );

      final p2p = ZeroSyncP2P(db: db, peerId: 'peer_node_a');

      db.execute('CREATE TABLE messages (id TEXT PRIMARY KEY, text TEXT);');
      db.logChange(
        tableName: 'messages',
        rowId: 'm1',
        jsonPayload: '{"id":"m1","text":"P2P secret"}',
      );

      p2p.outgoingP2pStream.listen((msg) {
        expect(msg, contains('peer_node_a'));
        expect(msg, contains('encrypted_payload'));
      });

      await p2p.broadcastLocalChangesToPeer();
      await p2p.dispose();
      db.close();
    });
  });
}
