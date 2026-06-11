import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_seller_address_page.dart';
import 'seller_address_page.dart';
import 'edit_seller_profile_page.dart';

class SellerProfilePage extends StatefulWidget {
  @override
  _SellerProfilePageState createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _storeName = 'Toko Sayur Segar';
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();

        if (sellerDoc.exists) {
          Map<String, dynamic>? data = sellerDoc.data() as Map<String, dynamic>?;
          setState(() {
            _storeName = data?['name'] ?? 'Toko Sayur Segar';
            _imageUrl = data?['imageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading seller profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Profil Penjual',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF4B6BFB),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                SizedBox(height: 30),
                _buildSectionTitle('Informasi Akun'),
                _buildProfileMenuItem(
                  icon: Icons.person,
                  title: 'Edit Profil',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditSellerProfilePage()),
                    );
                    if (result == true) {
                      _loadSellerProfile();
                    }
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.location_on,
                  title: 'Alamat Toko',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SellerAddressPage()),
                    );
                  },
                ),
                SizedBox(height: 30),
                _buildSectionTitle('Lainnya'),
                _buildProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Keluar',
                  onTap: () async {
                    await _auth.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
            child: _imageUrl == null
                ? Icon(Icons.store, size: 60, color: Colors.grey[400])
                : null,
          ),
          SizedBox(height: 10),
          Text(
            _storeName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF4B6BFB).withOpacity(0.1),
          child: Icon(icon, color: Color(0xFF4B6BFB)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
