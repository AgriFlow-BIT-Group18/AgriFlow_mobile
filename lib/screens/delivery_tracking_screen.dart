import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final ApiService _apiService = ApiService();
  dynamic _activeOrder;
  List<dynamic> _allDeliveries = [];
  bool _isLoading = true;
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    _fetchActiveDelivery();
  }

  Future<void> _fetchActiveDelivery() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        _userRole = (user['role'] ?? 'farmer').toString().toLowerCase();
      }

      if (_userRole == 'distributor' || _userRole == 'admin') {
        final deliveries = await _apiService.getDeliveries();
        setState(() => _allDeliveries = deliveries);
      } else {
        final orders = await _apiService.getMyOrders();
        // Find orders that are in 'delivery' or 'delivered' status
        final deliveryOrders = orders.where((o) {
          final status = (o['status'] ?? '').toLowerCase();
          return status == 'delivery' || status == 'delivered';
        }).toList();

        if (deliveryOrders.isNotEmpty) {
          setState(() => _activeOrder = deliveryOrders.first);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load delivery data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userRole == 'distributor' || _userRole == 'admin') {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F7),
        appBar: _buildAppBar(),
        body: _allDeliveries.isEmpty
            ? const Center(child: Text('No active deliveries'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _allDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = _allDeliveries[index];
                  final orderId = (delivery['order']?['_id'] ?? '').toString().toUpperCase();
                  final shortId = orderId.length >= 8 ? orderId.substring(orderId.length - 8) : orderId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: Color(0xFF2D6C50)),
                      title: Text('Delivery #DEL-$shortId'),
                      subtitle: Text('Status: ${delivery['status']?.toUpperCase()}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() {
                          _activeOrder = delivery['order'];
                          // Temporarily switch role to show details for this one
                          _userRole = 'farmer_view'; 
                        });
                      },
                    ),
                  );
                },
              ),
      );
    }

    if (_activeOrder == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F7),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No active deliveries', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Your orders will appear here when shipped', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchActiveDelivery,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _activeOrder;
    final status = (order['status'] ?? 'delivery').toString().toUpperCase();
    final orderId = (order['_id'] ?? '').toString().toUpperCase();
    final shortId = orderId.length >= 8 ? orderId.substring(orderId.length - 8) : orderId;
    final items = order['orderItems'] as List? ?? [];
    final address = order['shippingAddress']?['address'] ?? 'Farm Plot 42, Ashanti Region';
    final city = order['shippingAddress']?['city'] ?? 'Kumasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    children: [
                      // Order Header Card
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Delivery #DEL-$shortId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      Text('Order #$shortId', style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade500)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'DELIVERED' ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'DELIVERED' ? Colors.green.shade700 : Colors.orange.shade700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.blueGrey.shade100),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
                                      Text(status == 'DELIVERED' ? 'Delivered' : 'Today, 3:30 PM',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D6C50))),
                                    ],
                                  ),
                                  Row(
                                    children: items.take(2).map((i) => _buildAvatarBadge(i['name']?.toString().substring(0, 3).toUpperCase() ?? '?')).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Map Area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: const Color(0xFF2D6C50).withOpacity(0.2), shape: BoxShape.circle),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF2D6C50), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                                child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Driver Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: const Color(0xFF2D6C50).withOpacity(0.1), shape: BoxShape.circle),
                                child: const Center(child: Text('JK', style: TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold, fontSize: 18))),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jean-Baptiste K.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    Text('Toyota Hilux — GR-2847-22', style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade500)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(color: const Color(0xFF2D6C50).withOpacity(0.1), shape: BoxShape.circle),
                                child: IconButton(icon: const Icon(Icons.call, color: Color(0xFF2D6C50)), onPressed: () {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Route Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF2D6C50), size: 20),
                                  Container(height: 40, width: 1, margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(border: Border(left: BorderSide(color: const Color(0xFF2D6C50).withOpacity(0.3))))),
                                  const Icon(Icons.location_on, color: Colors.orange, size: 20),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRouteLocation('Pickup Location', 'AgriFlow Distribution Center'),
                                    const SizedBox(height: 24),
                                    _buildRouteLocation('Delivery Address', '$address, $city'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items in Shipment
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D6C50).withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ITEMS IN THIS SHIPMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5)),
                              const SizedBox(height: 12),
                              ...items.map((i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildShipmentItem(Icons.inventory_2_outlined, i['name'] ?? 'Product', '${i['qty']} units'),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (status != 'DELIVERED')
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(color: Color(0xFFF6F7F7)),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.verified),
                  label: const Text('Confirm Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6C50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text('Delivery Tracking', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF2D6C50)), onPressed: _fetchActiveDelivery),
      ],
    );
  }

  Widget _buildAvatarBadge(String text) {
    return Container(
      width: 32, height: 32,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(color: const Color(0xFF2D6C50).withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
    );
  }

  Widget _buildRouteLocation(String label, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildShipmentItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF2D6C50).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF2D6C50), size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
          ],
        ),
      ],
    );
  }
}
