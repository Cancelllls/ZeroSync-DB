import 'dart:io';
import 'package:test/test.dart';
import 'package:zerosync_db/zerosync_db.dart';

void main() {
  group('ZeroSync-DB Package Tests', () {
    final testDbPath = 'test_zerosync.db';

    tearDown(() {
      final f = File(testDbPath);
      if (f.existsSync()) f.deleteSync();
    });

    test('ZeroCrypto AES-256-GCM Encryption & Decryption', () {
      final crypto = ZeroCrypto('my-super-secret-key-12345');
      final original = 'Hello ZeroSync-DB! Top Secret Data';

      final ciphertext = crypto.encrypt(original);
      expect(ciphertext, isNot(equals(original)));
      expect(ciphertext.contains(':'), isTrue);

      final decrypted = crypto.decrypt(ciphertext);
      expect(decrypted, equals(original));
    });

    test('Hybrid Logical Clock (HLC) Deterministic Ordering', () {
      final hlc1 = Hlc(1000, 0, 'node_A');
      final hlc2 = Hlc(1000, 1, 'node_A');
      final hlc3 = Hlc(1001, 0, 'node_B');

      expect(hlc1.compareTo(hlc2), lessThan(0));
      expect(hlc2.compareTo(hlc3), lessThan(0));
    });

    test('ZeroSyncDatabase Local Writes & Change Logging', () async {
      final db = await ZeroSyncDatabase.open(
        path: testDbPath,
        secretKey: 'passphrase-secret',
        nodeId: 'node_test',
      );

      db.execute('CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT);');
      db.execute("INSERT INTO notes VALUES ('1', 'Secret Note');");
      db.logChange(
        tableName: 'notes',
        rowId: '1',
        jsonPayload: '{"id":"1","title":"Secret Note"}',
      );

      final changes = db.getUnsyncedChanges();
      expect(changes.length, equals(1));
      expect(changes.first['table_name'], equals('notes'));

      final encryptedPayload = changes.first['encrypted_payload']!;
      final decrypted = db.crypto.decrypt(encryptedPayload);
      expect(decrypted, contains('Secret Note'));

      db.close();
    });
  });
}
