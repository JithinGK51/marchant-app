import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import 'invoice_screen.dart';

class QuickScanScreen extends StatefulWidget {
  final List<Product> allProducts;
  final Map<String, double> initialCart;

  const QuickScanScreen({
    super.key, 
    required this.allProducts, 
    this.initialCart = const {},
  });

  @override
  State<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends State<QuickScanScreen> {
  late Map<String, double> _cart;
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.initialCart);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? "";
      if (code.isNotEmpty) {
        _processBarcode(code);
      }
    }
  }

  void _processBarcode(String code) {
    setState(() => _isProcessing = true);

    try {
      final product = widget.allProducts.firstWhere(
        (p) => p.barcode == code,
      );

      setState(() {
        _cart[product.id] = (_cart[product.id] ?? 0) + 1;
      });

      // Brief delay to prevent multiple scans of the same item in a split second
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    } catch (e) {
      // Product not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  double get _totalAmount {
    double total = 0;
    _cart.forEach((id, qty) {
      final p = widget.allProducts.firstWhere((element) => element.id == id);
      total += p.sellingPrice * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quick Scan Billing ⚡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Section: Live Scanner
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // Scanner Overlay
                Center(
                  child: Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: _isProcessing ? Colors.orange : Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),

          // Middle Section: Scanned Items List
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scanned Items (${_cart.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, size: 64, color: Colors.black12),
                                SizedBox(height: 16),
                                Text('Ready to scan...', style: TextStyle(color: Colors.black38)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _cart.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final id = _cart.keys.elementAt(index);
                              final qty = _cart[id]!;
                              final product = widget.allProducts.firstWhere((p) => p.id == id);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('₹${product.sellingPrice} / ${product.unit}', 
                                               style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              if (_cart[id]! > 1) {
                                                _cart[id] = _cart[id]! - 1;
                                              } else {
                                                _cart.remove(id);
                                              }
                                            });
                                          },
                                        ),
                                        Text('${qty % 1 == 0 ? qty.toInt() : qty}', 
                                             style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _cart[id] = _cart[id]! + 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: ElevatedButton(
          onPressed: _cart.isEmpty ? null : () async {
            final List<Map<String, dynamic>> items = [];
            _cart.forEach((id, qty) {
              final p = widget.allProducts.firstWhere((element) => element.id == id);
              items.add({
                'product_id': id,
                'name': p.name,
                'quantity': qty,
                'unit': p.unit,
                'price_per_unit': p.sellingPrice,
                'cost_per_unit': p.costPrice,
                'total_price': p.sellingPrice * qty,
              });
            });
            
            final navigator = Navigator.of(context);
            final result = await navigator.push(MaterialPageRoute(
              builder: (_) => InvoiceScreen(cartItems: items, total: _totalAmount),
            ));
            
            if (!mounted) return;
            if (result == true) {
              navigator.pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Review & Finalize Order'),
        ),
      ),
    );
  }
}
