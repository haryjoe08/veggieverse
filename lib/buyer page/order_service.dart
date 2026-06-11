import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder(
      List<CartItem> items,
      double totalAmount,
      String paymentMethod,
      String? voucherCode,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc();

    // Create order document
    batch.set(orderRef, {
      'buyerId': user.uid,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'voucherCode': voucherCode,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (var item in items) {
      final productRef = _firestore.collection('products').doc(item.id);

      // Update product stock and sold count
      batch.update(productRef, {
        'stock': FieldValue.increment(-item.quantity),
        'sold': FieldValue.increment(item.quantity),
      });

      // Fetch the product details to determine the sellerId
      final productSnapshot = await productRef.get();
      final productData = productSnapshot.data();
      if (productData == null) continue;

      final sellerId = productData['sellerId'];
      if (sellerId != null) {
        final sellerRef = _firestore.collection('sellers').doc(sellerId);

        // Update the seller's sales data
        batch.update(sellerRef, {
          'totalSales': FieldValue.increment(item.price * item.quantity),
          'totalOrders': FieldValue.increment(1),
        });

        // Add the order ID to the seller's order list (optional)
        final sellerOrderRef =
            sellerRef.collection('orders').doc(orderRef.id);
        batch.set(sellerOrderRef, {
          'orderId': orderRef.id,
          'totalAmount': totalAmount,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Mark voucher as used if applied
    if (voucherCode != null) {
      final voucherQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vouchers')
          .where('code', isEqualTo: voucherCode)
          .limit(1)
          .get();

      if (voucherQuery.docs.isNotEmpty) {
        batch.update(voucherQuery.docs.first.reference, {'isUsed': true});
      }
    }

    // Commit the batch
    try {
      await batch.commit();
      print('Order placed successfully');
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order. Please try again.');
    }
  }
}
