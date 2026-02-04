import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  // Une clé secrète propre à ARK pour renforcer le hachage
  static const String _appSalt = "ARK_PRO_PROJECT_2026_SECURITY_SALT_99";

  static String hashPassword(String password) {
    // On combine le mot de passe avec le sel
    final bytes = utf8.encode(password + _appSalt);
    // On génère le hachage SHA-256
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String storedHash) {
    return hashPassword(password) == storedHash;
  }
}
