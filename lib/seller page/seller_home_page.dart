import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sales_report_page.dart';
import 'orders_page.dart';
import 'products_list_page.dart';
import 'seller_profile_page.dart';
import 'package:intl/intl.dart';


class SellerHomePage extends StatefulWidget {
  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    SellerHomeContent(),
    OrdersPage(),
    SellerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Pesanan'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      selectedItemColor: Color(0xFF4B6BFB),
      unselectedItemColor: Colors.grey,
    );
  }
}

class SellerHomeContent extends StatefulWidget {
  @override
  _SellerHomeContentState createState() => _SellerHomeContentState();
}

class _SellerHomeContentState extends State<SellerHomeContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double totalSales = 0.0;
  List<FlSpot> weeklySalesData = [];
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

      weeklySalesData = List.generate(7, (index) => FlSpot(index.toDouble(), weeklySales[index] ?? 0));
    } catch (e) {
      print('Error loading weekly sales data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text('Hello, Seller', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              isLoading ? CircularProgressIndicator() : _buildSalesCard(),
              SizedBox(height: 30),
              Text('Menu Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _buildAdminMenu(),
              SizedBox(height: 30),
              Text('Grafik Penjualan Mingguan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              isLoading ? CircularProgressIndicator() : _buildWeeklySalesChart(),
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
            child: Image.asset('assets/box.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatRupiah(totalSales),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Total Penjualan',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAdminMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMenuCard(
          title: 'Statistik\nPenjualan',
          color: Color(0xFF4B6BFB),
          badge: '+1',
          imagePath: 'assets/sales_report.png',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SalesReportPage())),
        ),
        _buildMenuCard(
          title: 'Daftar\nProduk',
          color: Color(0xFF1E1E1E),
          imagePath: 'assets/products.png',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListPage())),
          actionButton: 'CEK',
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
                  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                  return Text(days[value.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 12));
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
          maxY: weeklySalesData.isEmpty ? 1 : weeklySalesData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b),
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

 Widget _buildMenuCard({
    required String title,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
    String? badge,
    String? actionButton,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: Center(child: Image.asset(imagePath, fit: BoxFit.contain))),
                SizedBox(height: 8),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ),
            if (actionButton != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF4B6BFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(actionButton, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }


  String _formatRupiah(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(amount);
  }
}