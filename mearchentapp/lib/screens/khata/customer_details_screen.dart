import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';
import '../orders/order_details_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await ApiService.getCustomerTransactions(widget.customer['id']);
      final summary = await ApiService.getCustomerSummary(widget.customer['id']);
      setState(() {
        _transactions = transactions;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showPaymentDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment 💸'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '₹'),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(context);
              try {
                await ApiService.recordPayment(widget.customer['id'], amount);
                _loadData();
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            }, 
            child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(title: Text(widget.customer['name'])),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppTheme.cardBg,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Debt', '₹${_summary?['total_debt']?.toStringAsFixed(0) ?? "0"}', Colors.black87),
                    _buildSummaryItem('Total Paid', '₹${_summary?['total_paid']?.toStringAsFixed(0) ?? "0"}', Colors.green),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Remaining Balance', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Text('₹${_summary?['balance']?.toStringAsFixed(2) ?? "0.00"}', 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _showPaymentDialog,
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                ? const Center(child: Text('No history found for this customer'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = _transactions[index];
                      return _buildTransactionTile(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> item) {
    final DateTime date = DateTime.parse(item['created_at']).toLocal();
    final bool isOrder = item['type'] == 'order';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: isOrder ? () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(order: item)
        )) : null,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isOrder ? Colors.orange : Colors.green).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOrder ? Icons.shopping_bag_outlined : Icons.payment_rounded,
            color: isOrder ? Colors.orange : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          isOrder ? 'Order #${item['id'].toString().substring(0, 8)}' : 'Payment Received',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isOrder ? "-" : "+"} ₹${item[isOrder ? 'final_amount' : 'amount']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOrder ? Colors.red.shade700 : Colors.green.shade700,
                fontSize: 16,
              ),
            ),
            if (isOrder)
              Text(
                item['payment_status'] == 'credit' ? 'PENDING' : 'PAID',
                style: TextStyle(
                  color: item['payment_status'] == 'credit' ? Colors.orange : Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
