import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/api_service.dart';


class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final ApiService _apiService = ApiService();
  String _userName = 'Kofi Mensah';
  String _userEmail = 'kofi.mensah@gmail.com';
  String _userPhone = '+233 24 000 0001';
  String _userRegion = 'Ashanti Region';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      setState(() {
        _userName = user['name'] ?? 'Farmer';
        _userEmail = user['email'] ?? '';
        _userPhone = user['phone'] ?? '';
        _userRegion = user['region'] ?? 'Senegal';
      });
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D6C50),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Icon(Icons.settings, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Color(0xFF2D6C50))),
                  const SizedBox(height: 12),
                  Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Farmer · $_userRegion', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            // Profile info
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoCard('Account Info', [
                    _buildInfoRow('Full Name', _userName),
                    _buildInfoRow('Email', _userEmail),
                    _buildInfoRow('Phone', _userPhone),
                    _buildInfoRow('Region', _userRegion),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
