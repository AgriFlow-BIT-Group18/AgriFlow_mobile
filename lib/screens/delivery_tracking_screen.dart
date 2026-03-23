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
  dynamic _selectedDelivery;
  List<dynamic> _allDeliveries = [];
  bool _isLoading = true;
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
        final deliveries = await _apiService.getMyDeliveries();
        if (deliveries.isNotEmpty) {
          setState(() => _selectedDelivery = deliveries.first);
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

    if (_selectedDelivery != null) {
      return _buildTrackingView(_selectedDelivery);
    }

    if (_userRole == 'distributor' || _userRole == 'admin') {
      return _buildDeliveriesList();
    }

    return _buildEmptyState();
  }

  Widget _buildDeliveriesList() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildAppBar('All Deliveries'),
      floatingActionButton: (_userRole == 'admin' || _userRole == 'distributor')
          ? FloatingActionButton(
              onPressed: _showCreateDeliveryDialog,
              backgroundColor: const Color(0xFF2D6C50),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping, color: Color(0xFF2D6C50)),
                    title: Text('Delivery #DEL-$shortId'),
                    subtitle: Text('Status: ${delivery['status']?.toUpperCase()}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedDelivery = delivery),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreateDeliveryDialog() async {
    final TextEditingController driverNameController = TextEditingController();
    final TextEditingController driverPhoneController = TextEditingController();
    String? selectedOrderId;
    List<dynamic> approvedOrders = [];

    // Fetch orders
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final allOrders = await _apiService.getAllOrders();
      approvedOrders = allOrders.where((o) => o['status'] == 'approved').toList();
      if (mounted) Navigator.pop(context); // Remove progress
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching orders: $e')));
        return;
      }
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schedule New Delivery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                   const Text('Select Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   approvedOrders.isEmpty
                       ? Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.grey[200],
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: const Row(
                             children: [
                               Icon(Icons.info_outline, color: Colors.grey),
                               SizedBox(width: 8),
                               Text('No approved orders available', style: TextStyle(color: Colors.grey)),
                             ],
                           ),
                         )
                       : DropdownButtonFormField<String>(
                           initialValue: selectedOrderId,
                           decoration: InputDecoration(
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                           ),
                           items: approvedOrders.map<DropdownMenuItem<String>>((o) {
                             final id = o['_id'].toString();
                             return DropdownMenuItem<String>(
                               value: id,
                               child: Text('#${id.substring(id.length - 8)} - ${o['user']['name']}'),
                             );
                           }).toList(),
                           onChanged: (val) => setModalState(() => selectedOrderId = val),
                         ),
                  const SizedBox(height: 16),
                  const Text('Driver Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: driverNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Jean-Baptiste',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Driver Phone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: driverPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+221...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6C50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (selectedOrderId == null || 
                            driverNameController.text.trim().isEmpty || 
                            driverPhoneController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez remplir tous les champs (Commande, Nom et Téléphone)'))
                          );
                          return;
                        }

                        // Simple phone validation
                        if (!RegExp(r'^\+?[\d\s-]{8,}$').hasMatch(driverPhoneController.text.trim())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Format de numéro de téléphone invalide'))
                          );
                          return;
                        }

                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          
                          await _apiService.createDelivery({
                            'order': selectedOrderId,
                            'driverName': driverNameController.text.trim(),
                            'driverPhone': driverPhoneController.text.trim(),
                          });
                          
                           if (mounted && context.mounted) {
                             Navigator.pop(context); // Close loading
                             Navigator.pop(context); // Close sheet
                             _fetchData();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Livraison créée avec succès !'), backgroundColor: Colors.green)
                             );
                           }
                        } catch (e) {
                          if (mounted && context.mounted) {
                            Navigator.pop(context); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de la création : ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: Colors.red,
                              )
                            );
                          }
                        }
                      },
                      child: const Text('Créer la Livraison', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildAppBar('Delivery Tracking'),
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
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6C50)),
              child: const Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView(dynamic delivery) {
    final order = delivery['order'] ?? {};
    final orderId = (order['_id'] ?? '').toString().toUpperCase();
    final shortId = orderId.length >= 8 ? orderId.substring(orderId.length - 8) : orderId;
    final status = (delivery['status'] ?? 'assigned').toString();
    final items = order['orderItems'] as List? ?? [];
    final address = order['shippingAddress']?['address'] ?? 'Farm Plot 42, Ashanti Region';
    final city = order['shippingAddress']?['city'] ?? 'Kumasi';
    final driverName = delivery['driverName'] ?? 'Jean-Baptiste K.';
    final estimatedArrival = delivery['estimatedDeliveryTime'] != null 
        ? DateTime.parse(delivery['estimatedDeliveryTime']).toLocal().toString().substring(11, 16)
        : '3:30 PM';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D6C50)),
          onPressed: () => setState(() => _selectedDelivery = null),
        ),
        title: const Text('Delivery Tracking', style: TextStyle(color: Color(0xFF334155), fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Color(0xFF2D6C50)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6C50).withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery #DEL-$shortId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Order #$shortId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Arrival', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Today, $estimatedArrival', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D6C50))),
                        ],
                      ),
                      Row(
                        children: items.take(2).map((i) => _buildItemInitials(i['name'] ?? 'P')).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Image / Map Placeholder
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1519003722824-194d4455a60c?q=80&w=1000&auto=format&fit=crop', // High quality delivery truck
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.near_me, color: Color(0xFF2D6C50), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'LIVE TRACKING ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF2D6C50),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6C50).withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2D6C50).withValues(alpha: 0.1),
                    child: Text(driverName.substring(0, 1), style: const TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Toyota Hilux — GR-2847-22', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFF2D6C50)),
                    onPressed: () {},
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D6C50).withValues(alpha: 0.05)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6C50).withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2D6C50), size: 18),
                      Container(width: 1, height: 30, color: const Color(0xFF2D6C50).withValues(alpha: 0.2)),
                      const Icon(Icons.home, color: Colors.orange, size: 18),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PICKUP LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Text('AgriFlow Distribution Center', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 16),
                        const Text('DELIVERY ADDRESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('$address, $city', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6C50).withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ITEMS IN THIS SHIPMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 12),
                  ...items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF2D6C50).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2, color: Color(0xFF2D6C50), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i['name'] ?? 'Product', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('${i['qty']} units', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Stepper
            _buildStepper(status),
            const SizedBox(height: 32),

            // Action Button
            if (status != 'delivered')
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    await _apiService.updateDeliveryStatus(delivery['_id'].toString(), 'delivered');
                    
                    if (mounted && context.mounted) {
                      Navigator.pop(context); // Close loading
                      _fetchData(); // Refresh UI
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delivery marked as completed!'), backgroundColor: Colors.green)
                      );
                    }
                  } catch (e) {
                    if (mounted && context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)
                      );
                    }
                  }
                },
                icon: const Icon(Icons.verified),
                label: const Text('Confirm Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6C50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  shadowColor: const Color(0xFF2D6C50).withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInitials(String name) {
    return Container(
      width: 28, height: 28,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6C50).withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStepper(String status) {
    int currentStep = 0;
    if (status == 'assigned') currentStep = 1;
    if (status == 'in_transit') currentStep = 2;
    if (status == 'delivered') currentStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep('Ready', currentStep >= 0),
        _buildConnector(currentStep >= 1),
        _buildStep('Shipped', currentStep >= 1),
        _buildConnector(currentStep >= 2),
        _buildStep('En Route', currentStep >= 2),
        _buildConnector(currentStep >= 3),
        _buildStep('Arrived', currentStep >= 3),
      ],
    );
  }

  Widget _buildStep(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2D6C50) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: active ? const Color(0xFF2D6C50) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? const Color(0xFF2D6C50) : Colors.grey.shade200,
      ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF2D6C50)), onPressed: _fetchData),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return Colors.blue;
      case 'in_transit': return Colors.orange;
      case 'delivered': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'READY';
      case 'in_transit': return 'EN ROUTE';
      case 'delivered': return 'DELIVERED';
      case 'failed': return 'FAILED';
      default: return status.toUpperCase();
    }
  }
}
