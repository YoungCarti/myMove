import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentCard {
  final String id;
  final String brand;
  final String last4;

  PaymentCard({required this.id, required this.brand, required this.last4});

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'last4': last4,
      };

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
        id: json['id'],
        brand: json['brand'],
        last4: json['last4'],
      );
}

class PaymentService {
  static String get _cardsKey {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return 'saved_cards_${user.uid}';
    }
    return '';
  }

  static Future<List<PaymentCard>> getCards() async {
    final key = _cardsKey;
    if (key.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final cardsString = prefs.getString(key);
    if (cardsString != null) {
      final List<dynamic> decoded = jsonDecode(cardsString);
      return decoded.map((e) => PaymentCard.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> addCard(PaymentCard card) async {
    final key = _cardsKey;
    if (key.isEmpty) return; // Do not save if no user is signed in

    final prefs = await SharedPreferences.getInstance();
    final currentCards = await getCards();
    currentCards.add(card);
    final encoded = jsonEncode(currentCards.map((c) => c.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  // Helper to add dummy cards for testing
  static Future<void> addDummyCards() async {
    final cards = await getCards();
    if (cards.isEmpty) {
      await addCard(PaymentCard(id: DateTime.now().millisecondsSinceEpoch.toString(), brand: 'Mastercard', last4: '9903'));
      await addCard(PaymentCard(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), brand: 'Visa', last4: '1000'));
    }
  }
}
