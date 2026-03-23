import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        _userRole = (user['role'] ?? 'farmer').toString().toLowerCase();
      }

      final orders = _userRole == 'distributor' || _userRole == 'admin'
          ? await _apiService.getAllOrders()
          : await _apiService.getMyOrders();
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => (o['status'] ?? '').toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.amber.shade700;
      case 'approved': return Colors.blue.shade700;
      case 'delivery': return Colors.orange.shade700;
      case 'delivered': return Colors.green.shade700;
      case 'rejected': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.amber.shade50;
      case 'approved': return Colors.blue.shade50;
      case 'delivery': return Colors.orange.shade50;
      case 'delivered': return Colors.green.shade50;
      case 'rejected': return Colors.red.shade50;
      default: return Colors.grey.shade100;
    }
  }

  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text('Order ID: ${(order['_id'] ?? '').toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6C50))),
            const SizedBox(height: 8),
            Text('Placed on: ${order['createdAt'] != null ? DateTime.parse(order['createdAt']).toLocal().toString().substring(0, 16) : ''}'),
            const SizedBox(height: 24),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: (order['orderItems'] as List).length,
                separatorBuilder: (_, index) => const Divider(height: 24),
                itemBuilder: (context, i) {
                  final item = order['orderItems'][i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Qty: ${item['qty']} @ ${item['price']} FCFA'),
                        ],
                      ),
                      Text('${((item['qty'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${(order['totalPrice'] ?? 0).toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D6C50))),
                ],
              ),
            ),
            if ((order['status'] ?? '').toLowerCase() == 'delivery')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // We would ideally tell MainLayout to switch to tab 3
                  // For now, let's just push it on top or rely on the user switching tabs
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6C50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Track Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,

        title: Text(_userRole == 'distributor' || _userRole == 'admin' ? 'All Orders' : 'My Orders', 
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders, color: const Color(0xFF2D6C50)),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Delivery', 'Delivered', 'Rejected'].map((f) {
                final isActive = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF2D6C50) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? const Color(0xFF2D6C50) : Colors.grey.shade300),
                      ),
                      child: Text(f, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _orders.isEmpty ? 'No orders yet' : 'No orders in this category',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            if (_orders.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Go to catalogue to place your first order', style: TextStyle(color: Colors.grey)),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final status = order['status'] ?? 'pending';
                            final items = (order['orderItems'] as List?)?.map((i) => '${i['qty']}x ${i['name']}').join(', ') ?? '';
                            final total = order['totalPrice'] ?? 0;
                            final date = order['createdAt'] != null
                                ? DateTime.parse(order['createdAt']).toLocal().toString().substring(0, 10)
                                : '';
                            final id = (order['_id'] ?? '').toString().toUpperCase();
                            final shortId = id.length >= 8 ? id.substring(id.length - 8) : id;

                            return GestureDetector(
                              onTap: () => _showOrderDetails(order),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('#$shortId', style: const TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold)),
                                        Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(items, style: const TextStyle(fontSize: 14, color: Color(0xFF334155)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(12)),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
