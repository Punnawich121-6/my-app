import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCard {
  final String holderName;
  final String lastFour;
  final String expiry; // MM/YY
  final String brand;  // Mastercard, Visa

  const SavedCard({
    required this.holderName,
    required this.lastFour,
    required this.expiry,
    required this.brand,
  });

  String get maskedNumber => '•••• •••• •••• $lastFour';

  Map<String, dynamic> toJson() => {
        'holderName': holderName,
        'lastFour': lastFour,
        'expiry': expiry,
        'brand': brand,
      };

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
        holderName: json['holderName'] as String,
        lastFour: json['lastFour'] as String,
        expiry: json['expiry'] as String,
        brand: json['brand'] as String,
      );
}

// Stores only non-sensitive display info (PCI-safe: no full PAN, no CVV).
// Data is encrypted by the OS: Keychain on iOS, EncryptedSharedPreferences on Android.
class CardStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _key = 'saved_card_v1';

  static Future<void> save(SavedCard card) =>
      _storage.write(key: _key, value: jsonEncode(card.toJson()));

  static Future<SavedCard?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return SavedCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete() => _storage.delete(key: _key);
}
