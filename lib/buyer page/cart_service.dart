import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  double price;
  final String imageUrl;
  int unit;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.unit,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'unit': unit,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      unit: (map['unit'] as num).toInt(),
      quantity: map['quantity'] as int,
    );
  }
}

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CartItem> _items = [];
  bool _isInitialized = false;

  List<CartItem> get items => _items;

  CartService() {
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    if (!_isInitialized) {
      await loadCart();
      _isInitialized = true;
    }
  }

  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final cartDoc = await _firestore.collection('carts').doc(user.uid).get();
        if (cartDoc.exists) {
          final cartData = cartDoc.data() as Map<String, dynamic>?;
          if (cartData != null && cartData['items'] != null) {
            _items = (cartData['items'] as List)
                .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
                .toList();
          } else {
            _items = [];
          }
        } else {
          _items = [];
        }
        notifyListeners();
      } catch (e) {
        print('Error loading cart: $e');
        _items = [];
      }
    }
  }

  Future<void> addItem(CartItem newItem) async {
    await _initializeCart();
    final user = _auth.currentUser;
    if (user != null) {
      try {
        int index = _items.indexWhere((item) => item.id == newItem.id);
        if (index != -1) {
          _items[index].quantity += newItem.quantity;
          _items[index].unit += newItem.unit;
          _items[index].price += newItem.price;
        } else {
          _items.add(newItem);
        }
        await _saveCart();
        notifyListeners();
      } catch (e) {
        print('Error adding item to cart: $e');
      }
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await _initializeCart();
    try {
      int index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = _items[index];
        final baseUnit = item.unit ~/ item.quantity;
        final basePrice = item.price / item.quantity;

        item.quantity = quantity;
        item.unit = baseUnit * quantity;
        item.price = basePrice * quantity;

        await _saveCart();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> removeItem(String id) async {
    await _initializeCart();
    _items.removeWhere((item) => item.id == id);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    await _initializeCart();
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('carts').doc(user.uid).set({
          'items': _items.map((item) => item.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving cart: $e');
      }
    }
  }

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.price);
  }
}
