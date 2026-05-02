import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';
import 'order_success_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const InvoiceScreen({super.key, required this.cartItems, required this.total});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isProcessing = false;
  final TextEditingController _discountController = TextEditingController(text: '0');
  double _discount = 0.0;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  double get _finalAmount => widget.total - _discount;

  double get _totalProfit {
    double profit = 0;
    for (var item in widget.cartItems) {
      double cost = item['cost_per_unit'] * item['quantity'];
      profit += (item['total_price'] - cost);
    }
    return profit;
  }

  Future<void> _confirmOrder({String paymentStatus = 'paid', String? customerId, double paidAmount = 0.0}) async {
    setState(() => _isProcessing = true);
    try {
      final totalPaid = paymentStatus == 'paid' && paidAmount == 0 ? _finalAmount : paidAmount;
      
      await ApiService.createOrder({
        "subtotal": widget.total,
        "discount": _discount,
        "final_amount": _finalAmount,
        "profit": _totalProfit - _discount,
        "items": widget.cartItems,
        "payment_status": paymentStatus,
        "customer_id": customerId,
        "paid_amount": totalPaid,
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OrderSuccessScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating order: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCreditDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final paidController = TextEditingController(text: '0');
    List<dynamic> existingCustomers = [];
    String? selectedCustomerId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Credit Order (Hudar) 📔'),
            content: FutureBuilder<List<dynamic>>(
              future: ApiService.getCustomers(),
              builder: (context, snapshot) {
                existingCustomers = snapshot.data ?? [];
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (existingCustomers.isNotEmpty) ...[
                        const Text('Select Existing Customer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          items: existingCustomers.map((c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text('${c['name']} (${c['phone']})'),
                          )).toList(),
                          onChanged: (v) {
                            setDialogState(() {
                              selectedCustomerId = v;
                              final c = existingCustomers.firstWhere((x) => x['id'] == v);
                              nameController.text = c['name'];
                              phoneController.text = c['phone'];
                            });
                          },
                        ),
                        const Divider(height: 32),
                        const Text('Or Enter New Details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      TextField(
                        controller: paidController, 
                        decoration: const InputDecoration(labelText: 'Paid Upfront (Optional)', prefixText: '₹'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                );
              },
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                  Navigator.pop(context);
                  
                  setState(() => _isProcessing = true);
                  try {
                      String finalId;
                      if (selectedCustomerId != null) {
                        finalId = selectedCustomerId!;
                      } else {
                        final customer = await ApiService.createOrGetCustomer({
                          "name": nameController.text,
                          "phone": phoneController.text,
                        });
                        finalId = customer['id'];
                      }
                      final upfrontPaid = double.tryParse(paidController.text) ?? 0.0;
                      await _confirmOrder(
                        paymentStatus: upfrontPaid >= _finalAmount ? 'paid' : 'credit', 
                        customerId: finalId,
                        paidAmount: upfrontPaid,
                      );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                    setDialogState(() => _isProcessing = false);
                  }
                }, 
                child: const Text('Confirm Credit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Review 🔥')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.cartItems.map((item) => _buildInvoiceItem(
              item['name'], 
              '${item['quantity']} ${item['unit']}', 
              '₹${item['total_price'].toStringAsFixed(2)}'
            )),
            const Divider(height: 32, color: Colors.black12),
            _buildSummaryRow('Subtotal', '₹${widget.total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount Amount', style: TextStyle(color: Colors.black87)),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _discount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.black12),
            _buildSummaryRow('Total Amount', '₹${_finalAmount.toStringAsFixed(2)}', isTotal: true),
            _buildSummaryRow('Expected Profit', '₹${(_totalProfit - _discount).toStringAsFixed(2)}', isProfit: true),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _showCreditDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text('Hudar (Credit)', style: TextStyle(color: Colors.orange)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _confirmOrder(),
                    child: _isProcessing 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Paid (Cash)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              Text(qty, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isProfit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isProfit ? Colors.blueAccent : Colors.black87,
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green : (isProfit ? Colors.blueAccent : Colors.black),
          )),
        ],
      ),
    );
  }
}
