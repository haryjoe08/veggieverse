import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_seller_address_page.dart';
import 'edit_seller_address_page.dart';

class SellerAddressPage extends StatefulWidget {
  @override
  _SellerAddressPageState createState() => _SellerAddressPageState();
}

class _SellerAddressPageState extends State<SellerAddressPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _address;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();

      if (sellerDoc.exists) {
        Map<String, dynamic>? data = sellerDoc.data() as Map<String, dynamic>?;
        setState(() {
          _address = data?['address'];
        });
      }
    } catch (e) {
      print('Error loading address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat alamat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alamat Toko'),
        backgroundColor: Color(0xFF4B6BFB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_address == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddSellerAddressPage()),
        );
      });
      return Container();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Color(0xFF4B6BFB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alamat Toko Anda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Berikut adalah detail alamat toko Anda yang terdaftar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddressRow(Icons.store, '${_address!['storeName']}'),
                    SizedBox(height: 12),
                    _buildAddressRow(Icons.location_on, '${_address!['streetAddress']}'),
                    SizedBox(height: 12),
                    _buildAddressRow(Icons.location_city, '${_address!['city']}, ${_address!['state']}'),
                    SizedBox(height: 12),
                    _buildAddressRow(Icons.local_post_office, 'Kode Pos: ${_address!['zipCode']}'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSellerAddressPage(currentAddress: _address!),
                ),
              );
              if (result == true) {
                _loadAddress(); // Reload address after editing
              }
            },
            icon: Icon(Icons.edit),
            label: Text('Edit Alamat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B6BFB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF4B6BFB), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

