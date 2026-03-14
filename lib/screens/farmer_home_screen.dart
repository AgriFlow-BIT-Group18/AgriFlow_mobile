import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'product_catalogue_screen.dart';
import '../widgets/main_layout.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final ApiService _apiService = ApiService();
  String _userName = 'Farmer';
  bool _isLoading = true;
  int _pendingCount = 0;
  int _deliveredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        _userName = user['name'] ?? 'Farmer';
      }

      final orders = await _apiService.getMyOrders();
      _pendingCount = orders.where((o) => o['status'] == 'pending' || o['status'] == 'approved').length;
      _deliveredCount = orders.where((o) => o['status'] == 'delivered').length;
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsCard(),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildWeatherTip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              _userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D6C50)),
            ),
          ],
        ),
        const CircleAvatar(
          backgroundColor: Color(0xFF2D6C50),
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6C50), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2D6C50).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Your Activity Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Orders', _pendingCount.toString(), 'Pending'),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('Success', _deliveredCount.toString(), 'Delivered'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sub) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          'Order Inputs',
          Icons.shopping_basket_outlined,
          const Color(0xFFE8F5E9),
          const Color(0xFF2D6C50),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 1))),
        ),
        _buildActionCard(
          'My Orders',
          Icons.assignment_outlined,
          const Color(0xFFE3F2FD),
          const Color(0xFF1976D2),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 2))),
        ),
        _buildActionCard(
          'Track Delivery',
          Icons.local_shipping_outlined,
          const Color(0xFFFFF3E0),
          const Color(0xFFF57C00),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 3))),
        ),
        _buildActionCard(
          'AI Help',
          Icons.auto_awesome_outlined,
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
          () {}, // For future AI Integration
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
            child: Icon(Icons.wb_sunny_outlined, color: Colors.amber.shade700),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Planting Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 2),
                Text(
                  'Good weather for maize planting in the Central region today.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
