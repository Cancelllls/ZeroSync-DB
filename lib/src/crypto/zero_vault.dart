import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:zerosync_db/src/crypto/zero_crypto.dart';

/// Multi-User Shared Vault Key Management & Access Grants.
class ZeroVault {
  final String vaultId;
  final ZeroCrypto _vaultCrypto;

  ZeroVault._(this.vaultId, this._vaultCrypto);

  static ZeroVault create(String vaultId, String vaultSecretKey) {
    return ZeroVault._(vaultId, ZeroCrypto(vaultSecretKey));
  }

  /// Encrypts vault access payload for sharing with a recipient.
  String createShareToken(String recipientPublicKey) {
    final payload = jsonEncode({
      'vault_id': vaultId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'checksum': sha256.convert(utf8.encode(recipientPublicKey)).toString(),
    });
    return _vaultCrypto.encrypt(payload);
  }

  /// Decrypts shared vault access token.
  static Map<String, dynamic> decryptShareToken(String shareToken, String vaultSecretKey) {
    final crypto = ZeroCrypto(vaultSecretKey);
    final decrypted = crypto.decrypt(shareToken);
    return jsonDecode(decrypted);
  }
}
