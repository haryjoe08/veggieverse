import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_page.dart';
import 'cart_service.dart';

class PaymentModal extends StatefulWidget {
  final double subtotal;
  final VoidCallback onCheckout;

  const PaymentModal({
    Key? key,
    required this.subtotal,
    required this.onCheckout,
  }) : super(key: key);

  @override
  _PaymentModalState createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'PICKUP'; // Default to pickup

  double get _total {
    return widget.subtotal + (_selectedPaymentMethod == 'COD' ? 5000 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPaymentMethodTile(
                  title: 'Pick Up',
                  value: 'PICKUP',
                ),
                SizedBox(height: 8),
                _buildPaymentMethodTile(
                  title: 'Cash on Delivery (COD)',
                  value: 'COD',
                ),
                SizedBox(height: 24),
                if (_selectedPaymentMethod == 'COD') ...[
                  _buildDetailRow(
                      'Subtotal', 'Rp ${widget.subtotal.toStringAsFixed(0)}'),
                  SizedBox(height: 8),
                  _buildDetailRow('Ongkos Kirim', 'Rp 5.000'),
                  SizedBox(height: 8),
                ],
                _buildDetailRow(
                  'Total',
                  'Rp ${_total.toStringAsFixed(0)}',
                  isTotal: true,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the modal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            paymentMethod: _selectedPaymentMethod,
                            items:
                                Provider.of<CartService>(context, listen: false)
                                    .items,
                            subtotal: widget.subtotal,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B140),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String value,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? Color(0xFF00B140)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                color: _selectedPaymentMethod == value
                    ? Color(0xFF00B140)
                    : Colors.black,
              ),
            ),
            if (_selectedPaymentMethod == value)
              Icon(
                Icons.check_circle,
                color: Color(0xFF00B140),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

