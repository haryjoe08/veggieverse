import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'profile_page.dart';
import 'product_page.dart';
import 'transaction_page.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'search_results_page.dart';
import 'package:provider/provider.dart';
import 'cart_service.dart';

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

class BuyerHomePage extends StatefulWidget {
  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _bestSellerStream;
  Stream<QuerySnapshot>? _promoStream;
  Stream<DocumentSnapshot>? _userStream;
  bool _isLoading = true;
  bool isClaimed = false;

  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFirebase();
    _checkVoucherStatus();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      _initProductStreams();
      _initUserStream();
    } catch (e) {
      print('Error initializing Firebase: $e');
      setState(() {
        _errorMessage = 'Failed to initialize Firebase: $e';
        _isLoading = false;
      });
    }
  }

  void _initProductStreams() {
    try {
      setState(() {
        _bestSellerStream = FirebaseFirestore.instance
            .collection('products')
            .where('isBestSeller', isEqualTo: true)
            .limit(5)
            .snapshots();
        _promoStream = FirebaseFirestore.instance
            .collection('products')
            .where('isPromo', isEqualTo: true)
            .limit(5)
            .snapshots();
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing product streams: $e');
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  void _initUserStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots();

      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .then((docSnapshot) {
        if (!docSnapshot.exists) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'name':
                capitalizeFirstLetter(currentUser.displayName ?? 'New User'),
            'email': currentUser.email,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildGreenHeader(context),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildGreenHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      color: Color.fromARGB(255, 0, 166, 61),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _userStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Colors.white);
                  }
                  String userName = 'Guest';
                  if (snapshot.hasData && snapshot.data != null) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    userName =
                        capitalizeFirstLetter(userData?['name'] ?? 'Guest');

                    if (userName == 'Guest') {
                      final currentUser = _auth.currentUser;
                      if (currentUser != null) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .update({
                          'name': capitalizeFirstLetter(
                              currentUser.displayName ?? 'New User')
                        });
                      }
                    }
                  } else if (snapshot.hasError) {
                    print('Error fetching user data: ${snapshot.error}');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search vegetables...',
                icon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    print('Performing search for: $query'); // Debug print
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: query.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Terlaris'),
            SizedBox(height: 15),
            _buildProductList(_bestSellerStream),
            SizedBox(height: 20),
            _buildDiscountSection(),
            SizedBox(height: 20),
            _buildSectionTitle('Promo'),
            SizedBox(height: 15),
            _buildProductList(_promoStream),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildProductList(Stream<QuerySnapshot>? productStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: productStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return _buildProductCard(data);
            }).toList(),
          ),
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
            builder: (context) => ProductDetailPage(productData: productData),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        productData['imageUrl'] ?? 'assets/placeholder.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error, color: Colors.red);
                        },
                      ),
                    ),
                  ),
                ),
                if (isPromo)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              capitalizeFirstLetter(productData['name'] ?? 'Unknown'),
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPromo)
              Text(
                'IDR ${originalPrice.toInt()}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            RichText(
              text: TextSpan(
                text: 'IDR ${discountedPrice.toInt()}',
                style: TextStyle(
                  color: Color(0xFF00B140),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '/Pcs',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  final cartService = Provider.of<CartService>(context, listen: false);
                  final double price = isPromo ? discountedPrice : originalPrice;
                  cartService.addItem(
                    CartItem(
                      id: productData['id'],
                      name: productData['name'],
                      price: price,
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
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Color(0xFF00B140),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkVoucherStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'User belum login';

      final voucherSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vouchers')
          .where('code', isEqualTo: 'DISKON50')
          .get();

      if (voucherSnapshot.docs.isNotEmpty) {
        setState(() {
          isClaimed = true;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildDiscountSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/promo-card.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount 50%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '*limited',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: isClaimed ? null : () async {
              try {
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) throw 'User belum login';

                final voucherSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('vouchers')
                    .where('code', isEqualTo: 'DISKON50')
                    .get();

                if (voucherSnapshot.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Voucher sudah diklaim sebelumnya!')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('vouchers')
                    .add({
                  'code': 'DISKON50',
                  'discountType': 'percentage',
                  'discountValue': 50,
                  'maxDiscount': 10000,
                  'isUsed': false,
                  'validUntil': DateTime.now().add(Duration(days: 30)),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Voucher berhasil diklaim!')),
                );
                setState(() {
                  isClaimed = true;
                });
              } catch (e) {
                print('Error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal klaim voucher: $e')),
                );
              }
            },
            child: Text(
              isClaimed ? 'Claimed' : 'Claim voucher',
              style: TextStyle(
                color: isClaimed ? Colors.grey : Color(0xFF00B140),
                fontFamily: 'Poppins',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20),
              disabledBackgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF00B140),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductPage()),
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Product',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Account',
        ),
      ],
    );
  }
}