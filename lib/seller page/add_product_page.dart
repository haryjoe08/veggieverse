import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController weightController = TextEditingController(text: "100");
  final TextEditingController stockController = TextEditingController(text: "1");
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = 'Vegetable'; // Default value
  final List<String> categories = ['Vegetable', 'Fruit', 'Spice'];
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  // Tambahkan instance Cloudinary
  final cloudinary = Cloudinary.full(
    apiKey: '553283937198626', // Masukkan API Key Anda
    apiSecret: 'A0BKEiEkAPyk8-Ciuo5NE79N5Yg', // Masukkan API Secret Anda
    cloudName: 'dh2wv474w', // Masukkan Cloud Name Anda
  );

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<String?> uploadImage(File image) async {
    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: image.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'product_images', // Folder di Cloudinary
        ),
      );

      if (response.isSuccessful) {
        print('Image uploaded successfully: ${response.secureUrl}');
        return response.secureUrl; // URL gambar
      } else {
        print('Upload failed:');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _saveProduct() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      String? imageUrl;
      if (_image != null) {
        imageUrl = await uploadImage(_image!);
        if (imageUrl == null) throw Exception('Failed to upload image');
      }

      DocumentReference docRef = await FirebaseFirestore.instance.collection('products').add({
        'id': '', // This will be updated after we get the document ID
        'name': nameController.text,
        'category': selectedCategory,
        'unit': int.parse(weightController.text),
        'stock': int.parse(stockController.text),
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'imageUrl': imageUrl,
        'sellerId': user.uid,
        'sellerName': user.displayName ?? 'Unknown Seller',
        'sellerEmail': user.email ?? 'No email provided',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the document with its own ID
      await docRef.update({'id': docRef.id});

      _showSnackBar('Produk berhasil ditambahkan', Colors.green);
      _resetForm();
    } catch (e) {
      print('Error saving product: $e');
      _showSnackBar('Gagal menambahkan produk: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateInputs() {
    if (nameController.text.isEmpty ||
        weightController.text.isEmpty ||
        stockController.text.isEmpty ||
        priceController.text.isEmpty) {
      _showSnackBar('Semua field harus diisi', Colors.red);
      return false;
    }
    return true;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _resetForm() {
    nameController.clear();
    weightController.text = "100";
    stockController.text = "1";
    priceController.clear();
    descriptionController.clear();
    setState(() {
      _image = null;
      selectedCategory = 'Vegetable';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Barang',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: getImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
                ),
              ),
              SizedBox(height: 24),
              _buildTextField('Nama Item', nameController),
              SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                    items: categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildNumberField('Unit (grams)', weightController, 10)),
                  SizedBox(width: 16),
                  Expanded(child: _buildNumberField('Stok', stockController, 1)),
                ],
              ),
              SizedBox(height: 24),
              _buildTextField('Harga Item', priceController, prefix: 'Rp ', keyboardType: TextInputType.number),
              SizedBox(height: 24),
              _buildTextField('description Produk', descriptionController, maxLines: 4),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B6BFB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? prefix, int? maxLines, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixText: prefix,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, int step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                int currentValue = int.parse(controller.text);
                if (currentValue > step) {
                  controller.text = (currentValue - step).toString();
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                int currentValue = int.parse(controller.text);
                controller.text = (currentValue + step).toString();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    stockController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

