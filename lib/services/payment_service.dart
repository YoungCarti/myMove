import 'dart:convert';
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
  static const String _cardsKey = 'user_payment_cards';

  static Future<List<PaymentCard>> getCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsString = prefs.getString(_cardsKey);
    if (cardsString != null) {
      final List<dynamic> decoded = jsonDecode(cardsString);
      return decoded.map((e) => PaymentCard.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> addCard(PaymentCard card) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCards = await getCards();
    currentCards.add(card);
    final encoded = jsonEncode(currentCards.map((c) => c.toJson()).toList());
    await prefs.setString(_cardsKey, encoded);
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
