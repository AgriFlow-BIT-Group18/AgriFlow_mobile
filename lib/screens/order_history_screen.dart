import 'package:flutter/material.dart';
import 'farmer_profile_screen.dart';
import 'product_catalogue_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7), // background-light
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0F172A),
          ), // slate-900
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100, // bg-slate-100
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.filter_list, color: Colors.blueGrey.shade700),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs (Horizontal Scroll)
            Container(
              color: const Color(0xFFF6F7F7),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildFilterTab('All', true),
                    const SizedBox(width: 8),
                    _buildFilterTab('Pending', false),
                    const SizedBox(width: 8),
                    _buildFilterTab('Approved', false),
                    const SizedBox(width: 8),
                    _buildFilterTab('In Delivery', false),
                    const SizedBox(width: 8),
                    _buildFilterTab('Delivered', false),
                    const SizedBox(width: 8),
                    _buildFilterTab('Rejected', false),
                  ],
                ),
              ),
            ),

            // Order List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildOrderCard(
                    orderId: '#FIDS-2024-0892',
                    date: 'Aug 12, 2024',
                    items: '50kg Fertilizer NPK, 2 bags Hybrid Corn Seeds',
                    status: 'Pending',
                    statusColor: Colors.amber.shade800,
                    statusBgColor: Colors.amber.shade100,
                    statusDotColor: Colors.amber.shade500,
                    price: '\$420.00',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderId: '#FIDS-2024-0885',
                    date: 'Aug 10, 2024',
                    items:
                        '100kg Urea Fertilizer, 5 bags Paddy Seeds (Premium)',
                    status: 'In Delivery',
                    statusColor: Colors.white,
                    statusBgColor: Colors.orange.shade500,
                    statusIcon: Icons.local_shipping,
                    price: '\$1,150.00',
                  ),
                  const SizedBox(height: 16),
                  _buildOrderCard(
                    orderId: '#FIDS-2024-0721',
                    date: 'Aug 05, 2024',
                    items: 'Organic Compost 200kg, Garden Tools Set',
                    status: 'Delivered',
                    statusColor: Colors.white,
                    statusBgColor: Colors.green.shade600,
                    statusIcon: Icons.check_circle,
                    price: '\$890.00',
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.8,
                    child: _buildOrderCard(
                      orderId: '#FIDS-2024-0612',
                      date: 'July 28, 2024',
                      items: 'Pesticide Alpha-Z, Irrigation Pump Spare Parts',
                      status: 'Rejected',
                      statusColor: Colors.white,
                      statusBgColor: Colors.red.shade600,
                      statusIcon: Icons.cancel,
                      price: '\$340.00',
                    ),
                  ),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Nav Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: Colors.blueGrey.shade200)),
        ),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 24,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              'Home',
              Icons.home_outlined,
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductCatalogueScreen(),
                  ),
                );
              },
            ),
            _buildNavItem('Orders', Icons.shopping_bag, true, onTap: () {}),
            _buildNavItem(
              'Market',
              Icons.storefront_outlined,
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductCatalogueScreen(),
                  ),
                );
              },
            ),
            _buildNavItem(
              'Profile',
              Icons.person_outline,
              false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FarmerProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2D6C50) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isActive ? null : Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.blueGrey.shade600,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String date,
    required String items,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    Color? statusDotColor,
    IconData? statusIcon,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  color: Color(0xFF2D6C50),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            items,
            style: const TextStyle(
              color: Color(0xFF334155), // slate-700
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusDotColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (statusIcon != null) ...[
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    IconData icon,
    bool isActive, {
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF2D6C50) : Colors.blueGrey.shade400;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
