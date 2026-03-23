import 'package:flutter/material.dart';
import '../screens/product_catalogue_screen.dart';
import '../screens/farmer_home_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/delivery_tracking_screen.dart';
import '../screens/farmer_profile_screen.dart';

import '../services/translation_service.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  final TranslationService _ts = TranslationService();

  final List<Widget> _screens = [
    const FarmerHomeScreen(),     // Home
    const ProductCatalogueScreen(), // Catalogue
    const OrderHistoryScreen(),    // Orders
    const DeliveryTrackingScreen(), // Delivery
    const FarmerProfileScreen(),   // Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2D6C50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: _ts.translate('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.grid_view), label: _ts.translate('catalogue')),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: _ts.translate('orders')),
          BottomNavigationBarItem(icon: const Icon(Icons.local_shipping), label: _ts.translate('delivery')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: _ts.translate('profile')),
        ],
      ),
    );
  }
}
