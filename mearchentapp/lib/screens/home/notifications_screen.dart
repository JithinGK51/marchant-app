import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: const Text('Notifications 🔔')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 16),
                    Text('No notifications yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isLowStock = notification['type'] == 'LOW_STOCK';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLowStock ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isLowStock ? Colors.red : Colors.green).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isLowStock ? Icons.warning_rounded : Icons.shopping_cart_rounded,
                              color: isLowStock ? Colors.redAccent : Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ?? 'Notification',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] ?? '',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getTimeAgo(notification['created_at']),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'unknown';
    final date = DateTime.parse(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
