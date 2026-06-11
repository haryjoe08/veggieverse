import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSellerAddressPage extends StatefulWidget {
  final Map<String, dynamic> currentAddress;

  EditSellerAddressPage({Key? key, required this.currentAddress}) : super(key: key);

  @override
  _EditSellerAddressPageState createState() => _EditSellerAddressPageState();
}

class _EditSellerAddressPageState extends State<EditSellerAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.currentAddress['storeName']);
    _streetController = TextEditingController(text: widget.currentAddress['streetAddress']);
    _cityController = TextEditingController(text: widget.currentAddress['city']);
    _stateController = TextEditingController(text: widget.currentAddress['state']);
    _zipCodeController = TextEditingController(text: widget.currentAddress['zipCode']);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No authenticated user found');
        }

        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .update({
          'address': {
            'storeName': _storeNameController.text,
            'streetAddress': _streetController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'zipCode': _zipCodeController.text,
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alamat berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        print('Error updating address: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui alamat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Alamat Toko'),
        backgroundColor: Color(0xFF4B6BFB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    'Edit Alamat Toko',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Perbarui informasi alamat toko Anda',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _storeNameController,
                      label: 'Nama Toko',
                      icon: Icons.store,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon isi nama toko';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _streetController,
                      label: 'Alamat Jalan',
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon isi alamat jalan';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _cityController,
                      label: 'Kota',
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon isi nama kota';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _stateController,
                      label: 'Provinsi',
                      icon: Icons.map,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon isi nama provinsi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _zipCodeController,
                      label: 'Kode Pos',
                      icon: Icons.local_post_office,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon isi kode pos';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateAddress,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4B6BFB),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF4B6BFB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF4B6BFB), width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

