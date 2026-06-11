import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_profile_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  ProductDetailPage({required this.productData});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  bool isFavorite = false;
  Map<String, dynamic>? sellerInfo;

  double _calculateDiscountedPrice(
      double originalPrice, int discountPercentage) {
    return originalPrice - (originalPrice * discountPercentage / 100);
  }

  Future<Map<String, dynamic>> _getSellerInfo(String sellerId) async {
    DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .get();
    return sellerDoc.data() as Map<String, dynamic>;
  }

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
    _incrementProductViews();
    quantity = (widget.productData['stock'] ?? 0) > 0 ? 1 : 0;
  }

  void _loadSellerInfo() async {
    if (widget.productData['sellerId'] != null) {
      final info = await _getSellerInfo(widget.productData['sellerId']);
      setState(() {
        sellerInfo = info;
      });
    }
  }

  Future<void> _incrementProductViews() async {
    final String productId = widget.productData['id'];
    final analyticsRef = FirebaseFirestore.instance.collection('analytics').doc(productId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(analyticsRef);
        if (!snapshot.exists) {
          transaction.set(analyticsRef, {'views': 1});
        } else {
          final int currentViews = snapshot.data()?['views'] ?? 0;
          transaction.update(analyticsRef, {'views': currentViews + 1});
        }
      });
    } catch (e) {
      print('Error updating product views: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int availableStock = widget.productData['stock'] ?? 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Product',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              padding: EdgeInsets.all(20),
              child: Image.network(
                widget.productData['imageUrl'] ?? 'assets/placeholder.png',
                fit: BoxFit.contain,
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF8F7FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.productData['isPromo'] == true)
                        Text(
                          'IDR ${widget.productData['price']?.toInt().toString() ?? '0'}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        'IDR ${widget.productData['isPromo'] == true ? _calculateDiscountedPrice(widget.productData['price']?.toDouble() ?? 0, widget.productData['disc'] ?? 0).toInt().toString() : widget.productData['price']?.toInt().toString() ?? '0'}',
                        style: TextStyle(
                          color: Color(0xFF00B140),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (widget.productData['isPromo'] == true)
                        Text(
                          '${widget.productData['disc']}% OFF',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (widget.productData['name'] as String?)
                                  ?.split(' ')
                                  .map((word) => word.isEmpty
                                      ? ''
                                      : '${word[0].toUpperCase()}${word.substring(1)}')
                                  .join(' ') ??
                              'Unknown',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    '${widget.productData['unit'] ?? ''} gram',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          availableStock > 0 ? Icons.check_circle : Icons.error,
                          color: availableStock > 0 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          availableStock > 0
                              ? 'Stock: $availableStock'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: availableStock > 0 ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(width: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text(
                            '${widget.productData['rating']?.toStringAsFixed(1) ?? '0.0'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(${widget.productData['totalRatings'] ?? 0} ulasan)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (sellerInfo != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerProfilePage(
                                  sellerId: widget.productData['sellerId']),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                  sellerInfo!['imageUrl'] ??
                                      'https://via.placeholder.com/150'),
                              radius: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sellerInfo!['name'] ?? 'Unknown Seller',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'View Store',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF00B140),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFF00B140),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    widget.productData['description'] ??
                        'No description available.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              color: quantity > 1 ? Color(0xFF00B140) : Colors.grey,
                              onPressed: quantity > 1 ? () {
                                setState(() {
                                  quantity--;
                                });
                              } : null,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                quantity.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              color: quantity < availableStock ? Color(0xFF00B140) : Colors.grey,
                              onPressed: quantity < availableStock ? () {
                                setState(() {
                                  quantity++;
                                });
                              } : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: availableStock > 0 ? Color(0xFF00B140) : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: availableStock > 0 ? () {
                        final cartService = Provider.of<CartService>(context, listen: false);
                        final double totalPrice = widget.productData['isPromo'] == true
                            ? _calculateDiscountedPrice(
                                widget.productData['price'].toDouble(),
                                widget.productData['disc']) * quantity
                            : widget.productData['price'].toDouble() * quantity;

                        cartService
                            .addItem(
                          CartItem(
                            id: widget.productData['id'],
                            name: widget.productData['name'],
                            price: totalPrice,
                            imageUrl: widget.productData['imageUrl'],
                            unit: widget.productData['unit'] * quantity,
                            quantity: quantity,
                          ),
                        )
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added to cart',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          );
                        }).catchError((error) {
                          print('Error adding item to cart: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to add item to cart',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      } : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            availableStock > 0 ? 'Add to cart' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}