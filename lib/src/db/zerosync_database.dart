import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:zerosync_db/src/crdt/hlc.dart';
import 'package:zerosync_db/src/crypto/zero_crypto.dart';

class ZeroSyncDatabase {
  final Database _sqliteDb;
  final ZeroCrypto crypto;
  final String nodeId;
  Hlc _clock;

  ZeroSyncDatabase._(this._sqliteDb, this.crypto, this.nodeId)
      : _clock = Hlc.now(nodeId);

  static Future<ZeroSyncDatabase> open({
    required String path,
    required String secretKey,
    String? nodeId,
  }) async {
    final effectiveNodeId = nodeId ?? const Uuid().v4().substring(0, 8);
    final sqliteDb = sqlite3.open(path);
    final crypto = ZeroCrypto(secretKey);

    final db = ZeroSyncDatabase._(sqliteDb, crypto, effectiveNodeId);
    db._initCrdtMetadataTable();
    return db;
  }

  void _initCrdtMetadataTable() {
    _sqliteDb.execute('''
      CREATE TABLE IF NOT EXISTS _zerosync_log (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        row_id TEXT NOT NULL,
        encrypted_payload TEXT NOT NULL,
        hlc_timestamp TEXT NOT NULL
      );
    ''');
  }

  Hlc get currentClock => _clock;

  Hlc tickClock() {
    _clock = _clock.increment(DateTime.now().millisecondsSinceEpoch);
    return _clock;
  }

  void execute(String sql, [List<Object?> parameters = const []]) {
    _sqliteDb.execute(sql, parameters);
  }

  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    return _sqliteDb.select(sql, parameters);
  }

  void logChange({
    required String tableName,
    required String rowId,
    required String jsonPayload,
  }) {
    final hlc = tickClock();
    final encrypted = crypto.encrypt(jsonPayload);
    final changeId = const Uuid().v4();

    _sqliteDb.execute('''
      INSERT INTO _zerosync_log (id, table_name, row_id, encrypted_payload, hlc_timestamp)
      VALUES (?, ?, ?, ?, ?)
    ''', [changeId, tableName, rowId, encrypted, hlc.toString()]);
  }

  List<Map<String, String>> getUnsyncedChanges() {
    final result = _sqliteDb.select('SELECT * FROM _zerosync_log');
    return result.map((row) {
      return {
        'id': row['id'].toString(),
        'table_name': row['table_name'].toString(),
        'row_id': row['row_id'].toString(),
        'encrypted_payload': row['encrypted_payload'].toString(),
        'hlc_timestamp': row['hlc_timestamp'].toString(),
      };
    }).toList();
  }

  void close() {
    _sqliteDb.dispose();
  }
}
