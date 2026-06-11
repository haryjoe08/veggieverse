import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';
import 'add_address_page.dart';
import 'package:provider/provider.dart';
import 'order_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final String paymentMethod;
  final List<CartItem> items;
  final double subtotal;

  const CheckoutPage({
    Key? key,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _voucherController = TextEditingController();
  Map<String, dynamic>? _userAddress;
  Map<String, dynamic>? _sellerAddress;
  bool _isLoading = true;
  double _discount = 0;
  String? _appliedVoucherCode;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (widget.paymentMethod == 'COD') {
          await _loadUserAddress(user.uid);
        } else {
          await _loadSellerAddress();
        }
      }
    } catch (e) {
      print('Error loading addresses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserAddress(String userId) async {
    final addressSnapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (addressSnapshot.docs.isNotEmpty) {
      setState(() {
        _userAddress = addressSnapshot.docs.first.data();
      });
    }
  }

  Future<void> _loadSellerAddress() async {
    if (widget.items.isNotEmpty) {
      final productSnapshot = await _firestore
          .collection('products')
          .doc(widget.items.first.id)
          .get();

      if (productSnapshot.exists) {
        final sellerId = productSnapshot.data()?['sellerId'];
        if (sellerId != null) {
          final sellerSnapshot =
              await _firestore.collection('sellers').doc(sellerId).get();

          if (sellerSnapshot.exists) {
            setState(() {
              _sellerAddress = sellerSnapshot.data()?['address'];
            });
          }
        }
      }
    }
  }

  Future<void> _applyVoucher() async {
    String voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) return;

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      QuerySnapshot voucherSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vouchers')
          .where('code', isEqualTo: voucherCode)
          .where('isUsed', isEqualTo: false)
          .get();

      if (voucherSnapshot.docs.isEmpty) {
        throw Exception('Voucher not found or already used');
      }

      var voucherData =
          voucherSnapshot.docs.first.data() as Map<String, dynamic>;
      DateTime validUntil = (voucherData['validUntil'] as Timestamp).toDate();

      if (validUntil.isBefore(DateTime.now())) {
        throw Exception('Voucher has expired');
      }

      double discountValue = voucherData['discountValue'].toDouble();
      double maxDiscount = voucherData['maxDiscount'].toDouble();

      double calculatedDiscount = widget.subtotal * (discountValue / 100);
      _discount =
          calculatedDiscount > maxDiscount ? maxDiscount : calculatedDiscount;

      setState(() {
        _appliedVoucherCode = voucherCode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher applied successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Pesanan Baru',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paymentMethod == 'PICKUP'
                          ? 'Pick up di:'
                          : 'Pengiriman ke:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildAddressSection(),
                    SizedBox(height: 24),
                    Text(
                      'Daftar Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._buildOrderItems(),
                    SizedBox(height: 24),
                    _buildVoucherSection(),
                    SizedBox(height: 24),
                    Text(
                      'Detail Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildOrderDetails(),
                    SizedBox(height: 24),
                    _buildProcessButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddressSection() {
    if (widget.paymentMethod == 'PICKUP') {
      if (_sellerAddress == null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Alamat penjual tidak tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        );
      }
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sellerAddress!['storeName'] ?? 'Toko ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 4),
            Text(
              _sellerAddress!['streetAddress'] ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${_sellerAddress!['city']}, ${_sellerAddress!['state']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              _sellerAddress!['zipCode'] ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (_userAddress == null) {
      return Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddAddressPage()),
            );
            _loadAddresses();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF5F5F5),
            foregroundColor: Colors.black87,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Tambahkan Alamat',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userAddress!['name'] ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
            SizedBox(height: 4),
          Text(
            _userAddress!['phone'] ?? '',
             style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
   
          Text(
            _userAddress!['streetAddress'] ?? '',
              style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
    
          Text(
            '${_userAddress!['city']}, ${_userAddress!['state']}',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            _userAddress!['zipCode'] ?? '',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems() {
    return widget.items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Berat: ${item.unit} gram',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Qty: ${item.quantity}',
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
              '${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voucher',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _voucherController,
                decoration: InputDecoration(
                  hintText: 'Enter voucher code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _applyVoucher,
              child: Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00B140),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_appliedVoucherCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Applied voucher: $_appliedVoucherCode',
              style: TextStyle(
                color: Color(0xFF00B140),
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    final deliveryFee = widget.paymentMethod == 'COD' ? 5000.0 : 0.0;
    final total = widget.subtotal + deliveryFee - _discount;

    return Column(
      children: [
        _buildDetailRow('Subtotal', widget.subtotal),
        SizedBox(height: 8),
        if (widget.paymentMethod == 'COD') ...[
          _buildDetailRow('Ongkos Kirim', deliveryFee),
          SizedBox(height: 8),
        ],
        if (_discount > 0) ...[
          _buildDetailRow('Discount', _discount, isDiscount: true),
          SizedBox(height: 8),
        ],
        Divider(color: Colors.grey[300]),
        SizedBox(height: 8),
        _buildDetailRow('Total', total, isTotal: true),
      ],
    );
  }

  Widget _buildDetailRow(String label, double amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Row(
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
              ? '- Rp ${amount.toStringAsFixed(0)}'
              : (isTotal
                  ? 'Rp ${amount.toStringAsFixed(0)}'
                  : amount.toStringAsFixed(0)),
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Poppins',
            color: isDiscount ? Color(0xFF00B140) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF00B140),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Proses Pesanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Validate address
      if (widget.paymentMethod == 'COD' && _userAddress == null) {
        throw Exception('Shipping address is required for COD orders');
      }

      // Fetch sellerId for each item
      List<Map<String, dynamic>> itemsWithSeller = await Future.wait(
        widget.items.map((item) async {
          DocumentSnapshot productSnapshot = await _firestore.collection('products').doc(item.id).get();
          String sellerId = productSnapshot.get('sellerId');
          return {...item.toMap(), 'sellerId': sellerId};
        })
      );

      // Create order in Firestore
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'buyerId': user.uid,
        'items': itemsWithSeller,
        'subtotal': widget.subtotal,
        'discount': _discount,
        'shippingFee': widget.paymentMethod == 'COD' ? 5000.0 : 0.0,
        'total': widget.subtotal +
            (widget.paymentMethod == 'COD' ? 5000.0 : 0.0) -
            _discount,
        'paymentMethod': widget.paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'shippingAddress': widget.paymentMethod == 'COD' ? _userAddress : null,
        'pickupAddress':
            widget.paymentMethod == 'PICKUP' ? _sellerAddress : null,
      });

      // Add the order ID to the document
      await orderRef.update({'id': orderRef.id});

      // Update product inventory
      for (var item in widget.items) {
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot productSnapshot = await transaction
              .get(_firestore.collection('products').doc(item.id));
          if (!productSnapshot.exists) {
            throw Exception('Product not found');
          }
          int currentStock = productSnapshot.get('stock');
          if (currentStock < item.quantity) {
            throw Exception('Insufficient stock for ${item.name}');
          }
          transaction.update(productSnapshot.reference, {
            'stock': currentStock - item.quantity,
            'soldCount': FieldValue.increment(item.quantity),
          });
        });
      }

      // Mark voucher as used
      if (_appliedVoucherCode != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('vouchers')
            .where('code', isEqualTo: _appliedVoucherCode)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            snapshot.docs.first.reference.update({'isUsed': true});
          }
        });
      }

      // Clear the cart
      await Provider.of<CartService>(context, listen: false).clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesanan berhasil diproses!')),
      );

      // Navigate to order confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(orderId: orderRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

