import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'products_list_page.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = 'Vegetable';
  final List<String> categories = ['Vegetable', 'Fruit', 'Spice'];
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  final cloudinary = Cloudinary.full(
    apiKey: '553283937198626', // Masukkan API Key Anda
    apiSecret: 'A0BKEiEkAPyk8-Ciuo5NE79N5Yg', // Masukkan API Secret Anda
    cloudName: 'dh2wv474w', // Masukkan Cloud Name Anda
  );


  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    nameController.text = widget.product.name;
    weightController.text = widget.product.unit.toString();
    stockController.text = widget.product.stock.toString();
    priceController.text = widget.product.price.toString();
    descriptionController.text = widget.product.description ?? '';
    selectedCategory = widget.product.category ?? 'Vegetable';
  }

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
          folder: 'product_images',
        ),
      );

      return response.isSuccessful ? response.secureUrl : null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _updateProduct() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = widget.product.imageUrl;
      if (_image != null) {
        imageUrl = await uploadImage(_image!);
        if (imageUrl == null) throw Exception('Failed to upload image');
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'name': nameController.text,
        'category': selectedCategory,
        'unit': int.parse(weightController.text),
        'stock': int.parse(stockController.text),
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields must be filled')),
      );
      return false;
    }
    return true;
  }

  Widget _buildCategoryDropdown() {
    return Column(
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
          'Edit Barang',
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
                      : widget.product.imageUrl != null
                          ? Image.network(widget.product.imageUrl!, fit: BoxFit.cover)
                          : Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
                ),
              ),
              SizedBox(height: 24),
              _buildTextField('Nama Item', nameController),
              SizedBox(height: 24),
              _buildCategoryDropdown(),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildNumberField('Unit', weightController, 10)),
                  SizedBox(width: 16),
                  Expanded(child: _buildNumberField('Stok', stockController, 1)),
                ],
              ),
              SizedBox(height: 24),
              _buildTextField('Harga Item', priceController, prefix: 'Rp ', keyboardType: TextInputType.number),
              SizedBox(height: 24),
              _buildTextField('Deskripsi Produk', descriptionController, maxLines: 4),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Perubahan',
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
}

