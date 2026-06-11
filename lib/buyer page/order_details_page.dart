import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? orderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _firestore.collection('orders').doc(widget.orderId).get();
      if (doc.exists) {
        setState(() {
          orderData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        throw Exception('Order not found');
      }
    } catch (e) {
      print('Error loading order details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': status});
      await _loadOrderDetails();
    
      // Send notification to the buyer
      await _sendOrderStatusNotification(status);
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated successfully',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status: $e',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendOrderStatusNotification(String status) async {
    try {
      String buyerId = orderData?['buyerId'];
      if (buyerId != null) {
        DocumentSnapshot buyerDoc = await _firestore.collection('users').doc(buyerId).get();
        String? buyerToken = buyerDoc.get('fcmToken');

        if (buyerToken != null) {
          await http.post(
            Uri.parse('YOUR_CLOUD_FUNCTION_URL'),
            body: json.encode({
              'token': buyerToken,
              'title': 'Order Status Update',
              'body': 'Your order #${widget.orderId} has been $status.',
              'data': {
                'orderId': widget.orderId,
                'status': status,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Widget _buildPaymentMethod() {
    String paymentMethod = orderData?['paymentMethod'] ?? 'Unknown';
    String paymentMethodAttachment =
        orderData?['paymentMethodAttachment'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Text(
          paymentMethod,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        if (paymentMethodAttachment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.network(
              paymentMethodAttachment,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }

  Widget _buildShippingAddress() {
    String paymentMethod = orderData?['paymentMethod'] ?? 'Unknown';
    Map<String, dynamic> shippingAddress = orderData?['shippingAddress'] ?? {};

    if (paymentMethod == 'PICKUP') {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alamat Pengiriman',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${shippingAddress['name'] ?? ''}\n'
          '${shippingAddress['phone'] ?? ''}\n'
          '${shippingAddress['streetAddress'] ?? ''}\n'
          '${shippingAddress['city'] ?? ''}, ${shippingAddress['zipCode'] ?? ''}',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderInfo(),
                    SizedBox(height: 24),
                    _buildPaymentMethod(),
                    SizedBox(height: 24),
                    _buildShippingAddress(),
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
                    if (orderData?['status'] == 'pending' || orderData?['status'] == 'processing')
                      _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderInfo() {
    String orderNumber = orderData?['id'] ?? widget.orderId;
    String customerName = orderData?['buyerId'] ?? 'Unknown Customer';
    String orderDate = orderData?['createdAt'] != null
        ? (orderData?['createdAt'] as Timestamp).toDate().toString()
        : 'Date not available';
    String status = orderData?['status'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.blue;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

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
          customerName,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 4),
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
    final items = List<Map<String, dynamic>>.from(orderData?['items'] ?? []);
    final currentUserItems = items
        .where((item) => item['sellerId'] == _auth.currentUser?.uid)
        .toList();

    return Column(
      children: currentUserItems
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl'] ?? ''),
                          fit: BoxFit.cover,
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
              ))
          .toList(),
    );
  }

  Widget _buildOrderSummary() {
    final items = List<Map<String, dynamic>>.from(orderData?['items'] ?? []);
    final currentUserItems = items
        .where((item) => item['sellerId'] == _auth.currentUser?.uid)
        .toList();

    double subtotal = currentUserItems.fold(0,
        (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
    double shippingFee = orderData?['shippingFee'] ?? 0;
    double discount = orderData?['discount'] ?? 0;
    double total = subtotal + shippingFee - discount;

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
        if (discount > 0)
          _buildSummaryRow('Diskon', -discount, isDiscount: true),
        Divider(height: 24),
        _buildSummaryRow('Total', total, isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, bool isDiscount = false}) {
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

  Widget _buildActionButtons() {
    if (orderData?['status'] == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus('processing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Terima',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus('rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Tolak',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      );
    } else if (orderData?['status'] == 'processing') {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus('shipping'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'Dikirim',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}