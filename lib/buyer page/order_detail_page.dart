import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  double rating = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (doc.exists) {
        setState(() {
          orderData = doc.data() as Map<String, dynamic>;
          rating = (orderData?['rating'] ?? 0).toDouble();
          isLoading = false;
        });
      } else {
        throw Exception('Order not found');
      }
    } catch (e) {
      print('Error loading order details: $e');
      setState(() => isLoading = false);
    }
  }

Future<void> _updateRating(double newRating) async {
  try {
    final List<dynamic> items = orderData?['items'] ?? [];
    final batch = FirebaseFirestore.instance.batch();

    // Update rating pada pesanan
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
    batch.update(orderRef, {'rating': newRating});

    // Update rating pada produk terkait
    for (var item in items) {
      final productRef = FirebaseFirestore.instance.collection('products').doc(item['id']);
      final productDoc = await productRef.get();

      if (productDoc.exists) {
        final productData = productDoc.data();
        final int totalRatings = productData?['totalRatings'] ?? 0;
        final double currentRating = productData?['rating'] ?? 0.0;

        final newTotalRatings = totalRatings + 1;
        final newAverageRating = ((currentRating * totalRatings) + newRating) / newTotalRatings;

        batch.update(productRef, {
          'rating': newAverageRating,
          'totalRatings': newTotalRatings,
        });
      }
    }

    // Commit batch update
    await batch.commit();

    setState(() {
      rating = newRating;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating berhasil diperbarui')),
    );
  } catch (e) {
    print('Error updating rating: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memperbarui rating')),
    );
  }
}


  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      final orderSnapshot = await orderRef.get();
      
      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> items = orderData['items'] ?? [];

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Update order status
      batch.update(orderRef, {'status': newStatus});

      if (newStatus.toLowerCase() == 'completed') {
        // Update analytics for each product
        for (var item in items) {
          final productId = item['id'];
          final quantity = item['quantity'] ?? 1;
          final analyticsRef = FirebaseFirestore.instance.collection('analytics').doc(productId);

          batch.set(analyticsRef, {
            'sold': FieldValue.increment(quantity)
          }, SetOptions(merge: true));
        }
      }

      // Commit the batch
      await batch.commit();

      // Reload order details
      await _loadOrderDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated successfully')),
      );
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderInfo(),
                    SizedBox(height: 24),
                    Text(
                      'Daftar Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildOrderItems(),
                    SizedBox(height: 24),
                    _buildOrderSummary(),
                    SizedBox(height: 24),
                    _buildPaymentInfo(),
                    SizedBox(height: 24),
                    _buildShippingInfo(),
                    SizedBox(height: 24),
                    _buildActionButton(),
                     SizedBox(height: 24),
                     _buildRatingSection()
                    
                  ],
                ),
              ),
            ),
    );
  }

  

  Widget _buildOrderInfo() {
    String orderNumber = orderData?['id'] ?? widget.orderId;
    String orderDate = orderData?['createdAt'] != null
        ? (orderData?['createdAt'] as Timestamp).toDate().toString()
        : 'Date not available';
    String status = orderData?['status'] ?? 'Unknown';

    Color statusColor = _getStatusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order #$orderNumber',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Text(
          orderDate,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    List<dynamic> items = orderData?['items'] ?? [];
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error, color: Colors.red);
                  },
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Berat: ${item['unit'] ?? ''} gram',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Qty: ${item['quantity'] ?? ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRatingSection() {
  if (orderData?['status'] != 'completed') {
    return SizedBox.shrink(); // Hanya tampilkan rating jika pesanan sudah selesai
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Beri Rating',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      SizedBox(height: 12),
      RatingBar.builder(
        initialRating: rating,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: true,
        itemCount: 5,
        itemSize: 36,
        itemBuilder: (context, _) => Icon(
          Icons.star,
          color: Colors.amber,
        ),
        onRatingUpdate: (newRating) {
          _updateRating(newRating);
        },
      ),
      SizedBox(height: 8),
      if (rating > 0)
        Text(
          'Rating diberikan: ${rating.toStringAsFixed(1)}',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
    ],
  );
}


  Widget _buildOrderSummary() {
    double subtotal = orderData?['subtotal'] ?? 0;
    double shippingFee = orderData?['shippingFee'] ?? 0;
    double discount = orderData?['discount'] ?? 0;
    double total = orderData?['total'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Pesanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12),
        _buildSummaryRow('Subtotal', subtotal),
        _buildSummaryRow('Ongkos Kirim', shippingFee),
        if (discount > 0) _buildSummaryRow('Diskon', -discount, isDiscount: true),
        Divider(height: 24),
        _buildSummaryRow('Total', total, isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            isDiscount
                ? '- Rp ${amount.abs().toStringAsFixed(0)}'
                : 'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Metode: ${orderData?['paymentMethod'] ?? 'N/A'}',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        if (orderData?['paymentMethodAttachment'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.network(
              orderData!['paymentMethodAttachment'],
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }

  Widget _buildShippingInfo() {
    Map<String, dynamic> shippingAddress = orderData?['shippingAddress'] ?? {};
    Map<String, dynamic> pickupAddress = orderData?['pickupAddress'] ?? {};
    String paymentMethod = orderData?['paymentMethod'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pengiriman',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        if (paymentMethod.toLowerCase() == 'pickup')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup di:',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              Text(
                '${pickupAddress['storeName'] ?? ''}\n'
                '${pickupAddress['streetAddress'] ?? ''}\n'
                '${pickupAddress['state'] ?? ''}\n'
                '${pickupAddress['city'] ?? ''}, ${pickupAddress['zipCode'] ?? ''}',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dikirim ke:',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              Text(
                '${shippingAddress['name'] ?? ''}\n'
                '${shippingAddress['phone'] ?? ''}\n'
                '${shippingAddress['streetAddress'] ?? ''}\n'
                '${shippingAddress['city'] ?? ''}, ${shippingAddress['zipCode'] ?? ''}',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    String status = orderData?['status'] ?? '';
    if (status.toLowerCase() == 'shipping') {
      return Center(
        child: ElevatedButton(
          onPressed: () => _updateOrderStatus('completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Order Received',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipping':
        return Colors.lightGreen;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}