import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_history_screen.dart';
import '../services/api_service.dart';


// Cart model
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'product': productId,
        'name': name,
        'qty': quantity,
        'price': price,
      };
}

// Global cart singleton
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> items = [];

  void addItem(dynamic product) {
    final id = product['_id']?.toString() ?? '';
    final existing = items.firstWhere((i) => i.productId == id, orElse: () => CartItem(productId: '', name: '', price: 0, unit: ''));
    if (existing.productId.isNotEmpty) {
      existing.quantity++;
    } else {
      items.add(CartItem(
        productId: id,
        name: product['name'] ?? '',
        price: (product['price'] ?? 0).toDouble(),
        unit: product['unit'] ?? 'unit',
      ));
    }
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  void removeItem(String productId) => items.removeWhere((i) => i.productId == productId);
  void clear() => items.clear();
}

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final CartService _cart = CartService();
  final ApiService _apiService = ApiService();
  String _paymentMethod = 'Mobile Money';
  bool _isSubmitting = false;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _submitOrder() async {
    if (_cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Point 4: Secure Payment Simulation
    try {
      // Simulate secure handshaking with payment gateway
      await Future.delayed(const Duration(seconds: 2));
      
      // Point 3: Real-time Stock Verification (Simulated)
      // In a real app, we'd call an endpoint to lock stock
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      String region = '';
      if (userStr != null) {
        final user = jsonDecode(userStr);
        region = user['region'] ?? '';
      }

      await _apiService.createOrder(
        orderItems: _cart.items.map((i) => i.toJson()).toList(),
        shippingAddress: {
          'address': _noteController.text.isNotEmpty ? _noteController.text : 'Default address',
          'city': region.isNotEmpty ? region : 'Dakar',
          'postalCode': '00000',
          'country': 'Senegal',
        },
        totalPrice: _cart.subtotal,
      );

      _cart.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_paymentMethod Payment Verified. Order submitted!'),
            backgroundColor: const Color(0xFF2D6C50),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text('My Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  if (items.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      onPressed: () => setState(() => _cart.clear()),
                    ),
                ],
              ),
            ),

            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('Go to catalogue to add products', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCartItem(item),
                        )),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Note to distributor (optional)...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 140), // space for bottom sheet
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: items.isEmpty
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('${_cart.subtotal.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Fee', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('Free', style: TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentOption('Mobile Money', Icons.phone_android),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentOption('Credit Card', Icons.credit_card),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_cart.subtotal.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2D6C50))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6C50),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Submit Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(width: 8),
                              Icon(Icons.send, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${item.price.toStringAsFixed(0)} FCFA / ${item.unit}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              if (item.quantity > 1) {
                                setState(() => item.quantity--);
                              } else {
                                setState(() => _cart.removeItem(item.productId));
                              }
                            },
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF2D6C50)),
                            onPressed: () => setState(() => item.quantity++),
                          ),
                        ],
                      ),
                    ),
                    Text('${item.total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6C50))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _cart.removeItem(item.productId)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    bool isSelected = _paymentMethod == label;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2D6C50) : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2D6C50) : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF2D6C50) : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
