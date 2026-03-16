import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/ai_assistant_screen.dart';
import 'screens/delivery_tracking_screen.dart';
import 'screens/farmer_onboarding_screen.dart';
import 'screens/farmer_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/product_catalogue_screen.dart';
import 'screens/shopping_cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriFlow Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6C50)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // Set the initial route for testing.
      // E.g. to test Farmer Onboarding:
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _ScreenNavigationDemo extends StatelessWidget {
  const _ScreenNavigationDemo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgriFlow Screens Generated')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Login Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          ListTile(
            title: const Text('Farmer Onboarding Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FarmerOnboardingScreen()),
            ),
          ),
          ListTile(
            title: const Text('Product Catalogue Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductCatalogueScreen()),
            ),
          ),
          ListTile(
            title: const Text('Farmer Profile Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FarmerProfileScreen()),
            ),
          ),
          ListTile(
            title: const Text('Shopping Cart Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShoppingCartScreen()),
            ),
          ),
          ListTile(
            title: const Text('Order History Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Delivery Tracking Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryTrackingScreen()),
            ),
          ),
          ListTile(
            title: const Text('AI Assistant Screen'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
            ),
          ),
        ],
      ),
    );
  }
}