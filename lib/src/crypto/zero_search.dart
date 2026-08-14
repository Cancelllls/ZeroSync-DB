import 'dart:convert';
import 'package:crypto/crypto.dart';

/// On-Device Blind Indexing for Searchable Encryption on Zero-Knowledge Databases.
class ZeroSearch {
  final List<int> _searchKey;

  ZeroSearch(String passphrase) : _searchKey = _deriveSearchKey(passphrase);

  static List<int> _deriveSearchKey(String passphrase) {
    return sha256.convert(utf8.encode('zerosearch_salt_$passphrase')).bytes;
  }

  /// Generates a deterministic HMAC-SHA256 blind index token for a search term.
  String generateBlindToken(String term) {
    final normalized = term.trim().toLowerCase();
    final hmac = Hmac(sha256, _searchKey);
    final digest = hmac.convert(utf8.encode(normalized));
    return digest.toString().substring(0, 32);
  }

  /// Extracts blind index tokens for all words in a query text.
  List<String> generateBlindTokensForText(String text) {
    final words = text.split(RegExp(r'\s+'));
    final tokens = <String>{};
    for (var w in words) {
      final clean = w.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.length >= 2) {
        tokens.add(generateBlindToken(clean));
      }
    }
    return tokens.toList();
  }
}
