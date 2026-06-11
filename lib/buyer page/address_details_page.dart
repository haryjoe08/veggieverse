import 'package:flutter/material.dart';
import 'add_address_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressDetailsPage extends StatelessWidget {
  final Map<String, dynamic> address;

  AddressDetailsPage({required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Address Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        
        child: Padding(
          
          padding: const EdgeInsets.all(16.0),
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressCard(),
              SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Divider(height: 24),
          _buildAddressRow(Icons.person, address['name'] ?? 'No name'),
          SizedBox(height: 8),
          _buildAddressRow(Icons.phone, address['phone'] ?? 'No phone'),
          SizedBox(height: 8),
          _buildAddressRow(Icons.home, address['streetAddress']),
          SizedBox(height: 8),
          _buildAddressRow(Icons.location_city, address['city']),
          SizedBox(height: 8),
          _buildAddressRow(Icons.map, address['state']),
          SizedBox(height: 8),
          _buildAddressRow(Icons.pin_drop, address['zipCode']),
        ],
      ),
    ),
  );
}

  Widget _buildAddressRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.edit),
          label: Text('Edit Address'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddAddressPage(existingAddress: address)),
            );
          },
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          icon: Icon(Icons.delete_outline, color: Colors.red),
          label: Text('Delete Address', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            _showDeleteConfirmationDialog(context);
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Address'),
          content: Text('Are you sure you want to delete this address?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteAddress(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteAddress(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(address['id'])
          .delete();
      Navigator.of(context).pop(); // Close the dialog
      Navigator.of(context).pop(); // Go back to the previous page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address deleted successfully')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting address: $e')),
      );
    }
  }
}

