import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.getUnifiedHistory();
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History 📜')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty 
          ? const Center(child: Text('No orders found'))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final item = _orders[index];
                  if (item['type'] == 'payment') {
                    return _buildPaymentCard(context, item);
                  }
                  return _buildOrderCard(context, item);
                },
              ),
            ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final DateTime date = DateTime.parse(payment['created_at']).toLocal();
    final String formattedDate = '${date.day} ${_getMonth(date.month)} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payment, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Recieved', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                Text('From ${payment['customers']?['name'] ?? 'Customer'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Text(formattedDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
          Text('+₹${payment['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final DateTime date = DateTime.parse(order['created_at']).toLocal();
    final String formattedDate = '${date.day} ${_getMonth(date.month)} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      )),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    Text(formattedDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order['payment_status'] == 'credit' 
                        ? Colors.orange.withValues(alpha: 0.1) 
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order['payment_status'] == 'credit' ? 'Khata 📔' : 'Paid ✅', 
                    style: TextStyle(
                      color: order['payment_status'] == 'credit' ? Colors.orange : Colors.green, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            if (order['payment_status'] == 'credit') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paid Amount', style: TextStyle(color: Colors.green, fontSize: 13)),
                  Text('₹${order['paid_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance Due', style: TextStyle(color: Colors.red, fontSize: 13)),
                  Text('₹${(order['final_amount'] - order['paid_amount']).toStringAsFixed(2)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Total', style: TextStyle(color: Color(0xFF64748B))),
                Text('₹${order['final_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
