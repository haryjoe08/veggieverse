import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesReportPage extends StatefulWidget {
  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double totalSales = 0.0;
  List<FlSpot> weeklySalesData = [];
  Map<String, int> analyticData = {
    'views': 0,
    'sold': 0,
  };
  List<Map<String, dynamic>> productAnalytics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _calculateTotalSales(),
      _loadWeeklySalesData(),
      _loadAnalyticData(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _calculateTotalSales() async {
    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .get();

      totalSales = querySnapshot.docs.fold(0.0, (sum, doc) {
        final items = doc.data()['items'] as List<dynamic>;
        return sum + items.where((item) => item['sellerId'] == currentUserId)
            .fold(0.0, (itemSum, item) => itemSum + (item['price'] ?? 0).toDouble() * (item['quantity'] ?? 1));
      });
    } catch (e) {
      print('Error calculating total sales: $e');
    }
  }

  Future<void> _loadWeeklySalesData() async {
    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .get();

      Map<int, double> weeklySales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>;
        final total = items.where((item) => item['sellerId'] == currentUserId).fold(
            0.0,
            (sum, item) =>
                sum + (item['price'] ?? 0) * (item['quantity'] ?? 1));

        if (total > 0) {
          final date = (data['createdAt'] as Timestamp).toDate();
          final weekday = date.weekday - 1; // 0 for Monday, 6 for Sunday

          weeklySales[weekday] = (weeklySales[weekday] ?? 0) + total;
        }
      }

      weeklySalesData = List.generate(
          7, (index) => FlSpot(index.toDouble(), weeklySales[index] ?? 0));
    } catch (e) {
      print('Error loading weekly sales data: $e');
    }
  }

  Future<void> _loadAnalyticData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      final String sellerId = user.uid;

      // Query products collection for documents where sellerId matches the current user's ID
      final productsQuery = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      int totalViews = 0;
      int totalSold = 0;
      List<Map<String, dynamic>> productData = [];

      // Iterate through each product
      for (var productDoc in productsQuery.docs) {
        final productId = productDoc.id;
        final productName =
            productDoc.data()['name'] as String? ?? 'Unknown Product';

        // Fetch the analytics document for this product
        final analyticsDoc =
            await _firestore.collection('analytics').doc(productId).get();

        if (analyticsDoc.exists) {
          final data = analyticsDoc.data() as Map<String, dynamic>;
          final views = data['views'] as int? ?? 0;
          final sold = data['sold'] as int? ?? 0;

          totalViews += views;
          totalSold += sold;

          productData.add({
            'id': productId,
            'name': productName,
            'views': views,
            'sold': sold,
          });
        }
      }

      setState(() {
        analyticData = {
          'views': totalViews,
          'sold': totalSold,
        };
        productAnalytics = productData;
      });
    } catch (e) {
      print('Error loading analytic data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penjualan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSalesCard(),
                    SizedBox(height: 24),
                    Text(
                      'Analytic',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildAnalyticCards(),
                    SizedBox(height: 24),
                    Text(
                      'Analytic Per Produk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildProductAnalyticsList(),
                    SizedBox(height: 24),
                    Text(
                      'Grafik Penjualan Mingguan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildWeeklySalesChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSalesCard() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Color(0xFFFFEFE9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/box.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatRupiah(totalSales),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Penjualan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAnalyticCard(
          icon: Icons.visibility,
          title: 'DILIHAT',
          value: _formatNumber(analyticData['views'] ?? 0),
          color: Colors.blue,
        ),
        _buildAnalyticCard(
          icon: Icons.shopping_cart,
          title: 'TERJUAL',
          value: _formatNumber(analyticData['sold'] ?? 0),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildWeeklySalesChart() {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Sen',
                    'Sel',
                    'Rab',
                    'Kam',
                    'Jum',
                    'Sab',
                    'Min'
                  ];
                  return Text(days[value.toInt()],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: weeklySalesData.isEmpty
              ? 1
              : weeklySalesData
                  .map((spot) => spot.y)
                  .reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: weeklySalesData,
              isCurved: true,
              color: Color(0xFF4B6BFB),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAnalyticsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: productAnalytics.length,
      itemBuilder: (context, index) {
        final product = productAnalytics[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(product['name'],
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text('${product['views']}',
                    style: TextStyle(fontFamily: 'Poppins')),
                SizedBox(width: 16),
                Icon(Icons.shopping_cart, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text('${product['sold']}',
                    style: TextStyle(fontFamily: 'Poppins')),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRupiah(double amount) {
    final formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(amount);
  }

  String _formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }
}