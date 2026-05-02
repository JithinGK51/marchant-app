import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.getProducts();
      final List<dynamic> filtered = [];

      for (var p in products) {
        final unit = p['unit'].toString().toLowerCase();
        final qty = (p['quantity'] as num).toDouble();

        bool isLowStock = false;
        if (['kg', 'l', 'ltr', 'kg.', 'l.'].any((u) => unit.contains(u))) {
          if (qty < 5) isLowStock = true;
        } else if (['pc', 'piece', 'unit'].any((u) => unit.contains(u))) {
          if (qty < 6) isLowStock = true;
        } else {
          // Default low stock if unit is unknown
          if (qty < 5) isLowStock = true;
        }

        if (isLowStock) {
          filtered.add(p);
        }
      }

      setState(() {
        _lowStockProducts = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Notifications 🔔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lowStockProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('All stock levels are healthy!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lowStockProducts.length,
                  itemBuilder: (context, index) {
                    final p = _lowStockProducts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        ),
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Current Stock: ${p['quantity']} ${p['unit']}'),
                        trailing: Text(
                          'LOW STOCK',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
