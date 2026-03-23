import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'distributor_map_screen.dart';
import 'ai_assistant_screen.dart';
import 'product_details_screen.dart';
import '../widgets/main_layout.dart';
import '../services/weather_service.dart';

import '../services/translation_service.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final ApiService _apiService = ApiService();
  final WeatherService _weatherService = WeatherService();
  final TranslationService _ts = TranslationService();
  String _userName = 'Farmer';
  int _pendingCount = 0;
  int _deliveredCount = 0;
  WeatherData? _weather;
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      String region = 'Ashanti Region';
      if (userStr != null) {
        final user = jsonDecode(userStr);
        _userName = user['name'] ?? 'Farmer';
        region = user['region'] ?? 'Ashanti Region';
      }

      final results = await Future.wait([
        _apiService.getMyOrders(),
        _weatherService.getLatestWeather(region),
        _apiService.getProducts(), // Reusing getProducts for recommendations simulation
      ]);

      final orders = results[0] as List<dynamic>;
      _weather = results[1] as WeatherData;
      final allProducts = results[2] as List<dynamic>;
      
      _pendingCount = orders.where((o) => o['status'] == 'pending' || o['status'] == 'approved').length;
      _deliveredCount = orders.where((o) => o['status'] == 'delivered').length;
      
      // Basic recommendation: pick 2 random products
      if (allProducts.isNotEmpty) {
        _recommendations = (List.from(allProducts)..shuffle()).take(2).toList();
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      if (mounted) setState(() {});
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
              Text(
                _ts.translate('quick_actions'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildWeatherTip(),
              if (_recommendations.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  _ts.translate('recommended'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                _buildRecommendations(),
              ],
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
              _ts.translate('welcome_back'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              _userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D6C50)),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainLayout(initialIndex: 4))),
          child: const CircleAvatar(
            backgroundColor: Color(0xFF2D6C50),
            child: Icon(Icons.person, color: Colors.white),
          ),
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
          BoxShadow(color: const Color(0xFF2D6C50).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_ts.translate('account_info'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(_ts.translate('orders'), _pendingCount.toString(), 'Pending'),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
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
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
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
          _ts.translate('order_inputs'),
          Icons.shopping_basket_outlined,
          const Color(0xFFE8F5E9),
          const Color(0xFF2D6C50),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainLayout(initialIndex: 1))),
        ),
        _buildActionCard(
          _ts.translate('my_orders'),
          Icons.assignment_outlined,
          const Color(0xFFE3F2FD),
          const Color(0xFF1976D2),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainLayout(initialIndex: 2))),
        ),
        _buildActionCard(
          _ts.translate('find_supplier'),
          Icons.map_outlined,
          const Color(0xFFE1F5FE),
          const Color(0xFF0288D1),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => DistributorMapScreen())),
        ),
        _buildActionCard(
          _ts.translate('track_delivery'),
          Icons.local_shipping_outlined,
          const Color(0xFFFFF3E0),
          const Color(0xFFF57C00),
          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainLayout(initialIndex: 3))),
        ),
        _buildActionCard(
          _ts.translate('ai_help'),
          Icons.auto_awesome_outlined,
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
            );
          },
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
          border: Border.all(color: color.withValues(alpha: 0.1)),
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
    if (_weather == null) return const SizedBox.shrink();
    
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
            child: Icon(
              _weather!.condition == 'Rainy' ? Icons.umbrella_outlined : Icons.wb_sunny_outlined, 
              color: Colors.amber.shade700
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather Tip (${_weather!.condition})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  _weather!.advice,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final product = _recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                    ? (product['imageUrl'].toString().startsWith('assets/')
                        ? Image.asset(product['imageUrl'], fit: BoxFit.cover)
                        : Image.network(product['imageUrl'], fit: BoxFit.cover))
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
              ),
            ),
            title: Text(product['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${product['price']} XOF / ${product['unit']}', style: const TextStyle(color: Color(0xFF2D6C50))),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
              );
            },
          ),
        );
      },
    );
  }
}
