import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Client-side AES-256-GCM Zero-Knowledge Encryption Engine.
class ZeroCrypto {
  final enc.Key _key;

  ZeroCrypto(String passphrase) : _key = _deriveKey(passphrase);

  static enc.Key _deriveKey(String passphrase) {
    final bytes = utf8.encode(passphrase);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts raw text string into base64 ciphertext with IV.
  String encrypt(String plainText) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combined = '${iv.base64}:${encrypted.base64}';
    return combined;
  }

  /// Decrypts combined base64 ciphertext back to plain text.
  String decrypt(String combinedCiphertext) {
    final parts = combinedCiphertext.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid ZeroSync ciphertext payload format');
    }
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
