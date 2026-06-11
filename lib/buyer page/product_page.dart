import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'profile_page.dart';
import 'buyer_home_page.dart';
import 'transaction_page.dart';
import 'product_detail_page.dart';
import 'cart_service.dart';

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Vegetable', 'Fruit', 'Spice'];
  Stream<QuerySnapshot>? _productsStream;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      _initProductsStream();
    } catch (e) {
      print('Error initializing Firebase: $e');
      setState(() {
        _errorMessage = 'Failed to initialize Firebase: $e';
        _isLoading = false;
      });
    }
  }

  void _initProductsStream() {
    try {
      setState(() {
        _productsStream =
            FirebaseFirestore.instance.collection('products').snapshots();
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing products stream: $e');
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  void _updateProductsStream(String filter) {
    setState(() {
      _isLoading = true;
      if (filter != 'All') {
        _productsStream = FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: filter)
            .snapshots();
      } else {
        _productsStream =
            FirebaseFirestore.instance.collection('products').snapshots();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Product',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFFF8F7FF),
        child: Column(
          children: [
            _buildFilterButtons(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _buildProductGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: _filters
              .map((filter) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: _buildFilterButton(filter),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    bool isSelected = _selectedFilter == text;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = text;
          _updateProductsStream(text);
        });
      },
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.green,
        side: BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(80, 36),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No products found'));
        }

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return _buildProductCard(data);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> productData) {
    bool isPromo = productData['isPromo'] ?? false;
    int discount = productData['disc'] ?? 0;
    double originalPrice = productData['price'] ?? 0;
    double discountedPrice = originalPrice - (originalPrice * discount / 100);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(productData: productData)),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/loading_placeholder.png',
                          image:
                              productData['imageUrl'] ?? 'assets/placeholder.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  if (isPromo)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    (productData['name'] as String?)
                            ?.split(' ')
                            .map((word) => word.isEmpty
                                ? ''
                                : '${word[0].toUpperCase()}${word.substring(1)}')
                            .join(' ') ??
                        'Unknown',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPromo)
                              Text(
                                'IDR ${originalPrice.toInt()}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'IDR ${discountedPrice.toInt()}',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/Pcs',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final cartService = Provider.of<CartService>(context, listen: false);
                          cartService.addItem(
                            CartItem(
                              id: productData['id'],
                              name: productData['name'],
                              price: discountedPrice,
                              imageUrl: productData['imageUrl'],
                              unit: productData['unit'],
                              quantity: 1,
                            ),
                          ).then((_) {
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
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF00B140),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontFamily: 'Poppins'),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins'),
      onTap: (index) {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BuyerHomePage()),
          );
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransactionsPage()),
          );
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Product'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}

