import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressPage extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;

  AddAddressPage({this.existingAddress});

  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _streetAddress = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _name = widget.existingAddress!['name'] ?? '';
      _phone = widget.existingAddress!['phone'] ?? '';
      _streetAddress = widget.existingAddress!['streetAddress'] ?? '';
      _city = widget.existingAddress!['city'] ?? '';
      _state = widget.existingAddress!['state'] ?? '';
      _zipCode = widget.existingAddress!['zipCode'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(
          widget.existingAddress != null ? 'Edit Address' : 'Add Address',
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
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _phone = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _streetAddress,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _streetAddress = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _city,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
                onSaved: (value) {
                  _city = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _state,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
                onSaved: (value) {
                  _state = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _zipCode,
                decoration: InputDecoration(
                  labelText: 'ZIP Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ZIP code';
                  }
                  return null;
                },
                onSaved: (value) {
                  _zipCode = value!;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                child: Text(
                  widget.existingAddress != null ? 'Update Address' : 'Save Address',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    try {
                      User? user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        if (widget.existingAddress != null) {
                          await FirebaseFirestore.instance
                              .collection('addresses')
                              .doc(widget.existingAddress!['id'])
                              .update({
                            'name': _name,
                            'phone': _phone,
                            'streetAddress': _streetAddress,
                            'city': _city,
                            'state': _state,
                            'zipCode': _zipCode,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          DocumentReference docRef = await FirebaseFirestore.instance.collection('addresses').add({
                            'userId': user.uid,
                            'name': _name,
                            'phone': _phone,
                            'streetAddress': _streetAddress,
                            'city': _city,
                            'state': _state,
                            'zipCode': _zipCode,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await docRef.update({'id': docRef.id});
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.existingAddress != null
                                  ? 'Address updated successfully'
                                  : 'Address added successfully',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      } else {
                        throw Exception('User not logged in');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error ${widget.existingAddress != null ? 'updating' : 'adding'} address: $e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
