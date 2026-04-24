import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['order_items'] ?? [];
    final DateTime date = DateTime.parse(order['created_at']).toLocal();
    final String formattedDate = '${date.day} ${_getMonth(date.month)} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: Text('Order #${order['id'].toString().substring(0, 8)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Order Date', value: formattedDate),
                  const _DetailRow(label: 'Status', value: 'Completed', valueColor: Colors.green),
                  const _DetailRow(label: 'Payment', value: 'Cash'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Items Ordered', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            ...items.map((item) {
              final String prodName = item['products'] != null ? item['products']['name'] : 'Product';
              return _buildItemTile(
                prodName, 
                '${item['quantity']} units', 
                '₹${item['total_price']}'
              );
            }),
            const SizedBox(height: 32),
            Text('Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _DetailRow(label: 'Total Items', value: items.length.toString()),
            const Divider(color: Color(0xFFE2E8F0), height: 32),
            _DetailRow(label: 'Total Amount', value: '₹${order['final_amount']}', isBold: true),
            _DetailRow(label: 'Total Profit', value: '₹${order['profit']}', valueColor: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildItemTile(String name, String qty, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(qty, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({required this.label, required this.value, this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? const Color(0xFF1E293B),
            fontSize: isBold ? 18 : 14,
          )),
        ],
      ),
    );
  }
}
