import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_product_page.dart';
import 'add_product_page.dart';
import 'add_seller_address_page.dart';

class Product {
  String id;
  String name;
  double price;
  String? imageUrl;
  String? category;
  int unit;
  int stock;
  String? description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.category,
    this.description,
    required this.unit,
    required this.stock,
  
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'],
      description: data['description'],
      unit: data['unit'] ?? 0,
      stock: data['stock'] ?? 0,
   
    );
  }
}

class ProductsListPage extends StatefulWidget {
  @override
  _ProductsListPageState createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  List<Product> products = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;

  List<String> categories = ['All', 'Vegetable', 'Fruit', 'Spice'];

  @override
  void initState() {
    super.initState();
    _checkAddressAndLoadProducts();
  }

  Future<void> _checkAddressAndLoadProducts() async {
    setState(() {
      _isLoading = true;
    });

    bool hasAddress = await _userHasAddress();
    if (hasAddress) {
      await _loadProducts();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        products = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }
  void _deleteProduct(String productId, String productName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName"?'),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              try {
                // Hapus produk dari Firestore
                await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                Navigator.of(context).pop();

                // Refresh data produk
                _loadProducts();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Produk "$productName" telah dihapus.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus produk: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}


  Future<bool> _userHasAddress() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(currentUser.uid)
        .get();

    return userDoc.data() != null &&
        (userDoc.data() as Map<String, dynamic>)['address'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text(
          'Daftar Produk',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : FutureBuilder<bool>(
                future: _userHasAddress(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == true) {
                    return _buildProductList();
                  } else {
                    return Center(
                      child: ElevatedButton(
                        child: Text('Tambahkan Alamat Terlebih Dahulu'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddSellerAddressPage()),
                          ).then((_) => _checkAddressAndLoadProducts());
                        },
                      ),
                    );
                  }
                },
              ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildProductList() {
    List<Product> filteredProducts = products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          (_selectedCategory == 'All' || product.category == _selectedCategory);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            'Katalog Produk',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B6BFB),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Color(0xFF4B6BFB).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? Color(0xFF4B6BFB)
                          : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3 / 4,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: _buildProductCard(filteredProducts[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Pastikan ini ada
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product.imageUrl ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView( // Menambahkan scroll untuk menghindari overflow
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Pastikan ini ada
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stock: ${product.stock}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: Icon(Icons.edit, color: Colors.white, size: 16),
                          label: Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProductPage(product: product),
                              ),
                            );
                            _loadProducts();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: TextButton.icon(
                          icon: Icon(Icons.delete, size: 16, color: Colors.white),
                          label: Text('Hapus', style: TextStyle(fontSize: 12, color: Colors.white)),
                          onPressed: () => _deleteProduct(product.id, product.name),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FutureBuilder<bool>(
      future: _userHasAddress(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              );
              _loadProducts();
            },
            icon: Icon(Icons.add),
            label: Text('Tambah Produk'),
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF4B6BFB),
          );
        } else {
          return SizedBox.shrink(); // Hide FAB if user has no address
        }
      },
    );
  }
}