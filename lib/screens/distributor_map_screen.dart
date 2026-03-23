import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DistributorMapScreen extends StatefulWidget {
  const DistributorMapScreen({super.key});

  @override
  State<DistributorMapScreen> createState() => _DistributorMapScreenState();
}

class _DistributorMapScreenState extends State<DistributorMapScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _distributors = [];
  
  // Simulated current location (Ouagadougou, Burkina Faso)
  final double currentLat = 12.3714;
  final double currentLng = -1.5197;

  @override
  void initState() {
    super.initState();
    _fetchDistributors();
  }

  Future<void> _fetchDistributors() async {
    setState(() => _isLoading = true);
    try {
      // Fetching nearby distributors within 50km
      final data = await _apiService.getNearbyDistributors(currentLat, currentLng, distance: 50);
      setState(() => _distributors = data);
    } catch (e) {
      debugPrint('Error fetching distributors: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Find Distributors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6C50)))
                : _distributors.isEmpty
                    ? _buildEmptyState()
                    : _buildDistributorList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Showing distributors near', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const Text('Your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D6C50))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 20),
                SizedBox(width: 12),
                Text('Search by city or name...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributorList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _distributors.length,
      itemBuilder: (context, index) {
        final d = _distributors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_outlined, color: Color(0xFF2D6C50), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(d['address'] ?? 'Official Distributor', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF2D6C50), size: 14),
                        const SizedBox(width: 4),
                        const Text('1.2 km away', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            if (d['location'] != null) {
                              final coords = d['location']['coordinates'];
                              _openMap(coords[1], coords[0]);
                            }
                          },
                          child: const Text('View Map', style: TextStyle(color: Color(0xFF2D6C50), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No distributors found nearby', style: TextStyle(color: Colors.grey, fontSize: 16)),
          TextButton(onPressed: _fetchDistributors, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
