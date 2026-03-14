import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'shopping_cart_screen.dart';
import '../services/api_service.dart';

class ProductCatalogueScreen extends StatefulWidget {
  const ProductCatalogueScreen({super.key});

  @override
  State<ProductCatalogueScreen> createState() => _ProductCatalogueScreenState();
}

class _ProductCatalogueScreenState extends State<ProductCatalogueScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _userName = 'Farmer';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _fetchProducts();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      setState(() {
        _userName = user['name'] ?? 'Farmer';
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedCategory == 'All') return _products;
    return _products.where((p) => p['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, $_userName 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF2D6C50), size: 14),
                              SizedBox(width: 4),
                              Text('Dakar, Senegal', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.notifications_outlined, color: Color(0xFF2D6C50)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search seeds, fertilizers...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', null, _selectedCategory == 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Seeds', '🌱', _selectedCategory == 'Seed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Fertilizers', '🌿', _selectedCategory == 'Fertilizer'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pesticides', '🪲', _selectedCategory == 'Pesticide'),
                ],
              ),
            ),

            // Product Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen())).then((_) => setState(() {})),
            backgroundColor: const Color(0xFF2D6C50),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          if (CartService().count > 0)
            Positioned(
              right: 0, top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('${CartService().count}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? emoji, bool isActive) {
    String categoryKey = label;
    if (label == 'Seeds') categoryKey = 'Seed';
    if (label == 'Fertilizers') categoryKey = 'Fertilizer';
    if (label == 'Pesticides') categoryKey = 'Pesticide';

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2D6C50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[Text(emoji), const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final inStock = (product['stockQuantity'] ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(product['unit'] ?? 'unit', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: inStock ? Colors.green : Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(inStock ? 'In Stock' : 'Out of Stock', style: const TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${product['price']} FCFA', style: const TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: inStock
                  ? () {
                      CartService().addItem(product);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product['name']} added to cart'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF2D6C50),
                        ),
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6C50),
                side: const BorderSide(color: Color(0xFF2D6C50)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
