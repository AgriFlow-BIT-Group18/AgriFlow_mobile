import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getNotifications();
      setState(() => _notifications = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _apiService.markNotificationAsRead(id);
      _fetchNotifications();
    } catch (e) {
      // Sliently fail or log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic n) {
    final bool isRead = n['isRead'] ?? false;
    final DateTime createdAt = DateTime.parse(n['createdAt']);
    final String timeAgo = DateFormat.MMMd().add_Hm().format(createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: isRead ? Colors.white : const Color(0xFFEDF7F2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(n['type']),
          child: Icon(_getTypeIcon(n['type']), color: Colors.white, size: 20),
        ),
        title: Text(
          n['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(n['message'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () {
          if (!isRead) _markAsRead(n['_id']);
        },
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'order': return Colors.blue;
      case 'delivery': return const Color(0xFF2D6C50);
      default: return Colors.orange;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'order': return Icons.shopping_basket;
      case 'delivery': return Icons.local_shipping;
      default: return Icons.info;
    }
  }
}
