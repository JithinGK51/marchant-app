import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import 'invoice_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _categories = [{'id': 'all', 'name': 'All'}];
  List<Product> _allProducts = [];
  final Map<String, double> _cart = {}; // product_id -> quantity
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.getCategories();
      final List<Product> prods = (await ApiService.getProducts()).map((e) => Product.fromJson(e)).toList();
      
      final newCategories = [{'id': 'all', 'name': 'All'}, ...cats];
      final newController = TabController(length: newCategories.length, vsync: this);

      setState(() {
        _categories = newCategories;
        _allProducts = prods;
        _tabController.dispose();
        _tabController = newController;
        _isLoading = false;
      });
      debugPrint("Loaded ${_categories.length} categories and ${_allProducts.length} products");
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {});
  }

  void _addToCart(Product product, {double qty = 1.0}) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + qty;
    });
  }

  void _showQuantityDialog(Product product) {
    final controller = TextEditingController();
    bool isKgOrL = ['kg', 'l', 'ltr', 'kg.', 'l.'].contains(product.unit.toLowerCase());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Quantity (${product.unit})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isKgOrL) ...[
              Wrap(
                spacing: 8,
                children: [0.25, 0.5, 1.0, 2.0, 5.0].map((val) => ActionChip(
                  label: Text('$val${product.unit}'),
                  onPressed: () {
                    _addToCart(product, qty: val);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Enter Custom Quantity',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null && qty > 0) {
                _addToCart(product, qty: qty);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  double get _cartTotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final p = _allProducts.firstWhere((element) => element.id == id);
      total += p.sellingPrice * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order 🛒'),
        bottom: _isLoading ? null : PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              TabBar(
                key: ValueKey('tabbar_${_categories.length}'),
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryColor,
                tabs: _categories.map((c) => Tab(text: c['name'])).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
        key: ValueKey('tabview_${_categories.length}'),
        controller: _tabController,
        children: _categories.map((c) => _buildProductGrid(c['id'].toString())).toList(),
      ),
      bottomNavigationBar: _cart.isEmpty ? null : _buildCartSummary(),
    );
  }

  Widget _buildProductGrid(String categoryId) {
    final filtered = _allProducts.where((p) {
      bool matchesCategory = (categoryId == 'all') || (p.categoryId == categoryId);
      bool matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
    
    debugPrint("Category $categoryId: ${filtered.length} products found");

    if (filtered.isEmpty) {
      return const Center(child: Text('No products found here 🔍'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        final cartQty = _cart[product.id] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(child: Icon(Icons.shopping_basket_outlined, color: AppTheme.primaryColor, size: 40)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                    Text('₹${product.sellingPrice} / ${product.unit}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (cartQty > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setState(() {
                              if (_cart[product.id]! > 0.1) {
                                // For pieces, decrement by 1. For weight, remove item to re-select
                                bool isPiece = product.unit.toLowerCase().contains('pc') || product.unit.toLowerCase().contains('piece');
                                if (isPiece && _cart[product.id]! > 1) {
                                  _cart[product.id] = _cart[product.id]! - 1;
                                } else {
                                  _cart.remove(product.id);
                                }
                              } else {
                                _cart.remove(product.id);
                              }
                            }),
                          ),
                          Text(
                            cartQty % 1 == 0 ? cartQty.toInt().toString() : cartQty.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            onPressed: () {
                              bool isPiece = product.unit.toLowerCase().contains('pc') || product.unit.toLowerCase().contains('piece');
                              if (isPiece) {
                                _addToCart(product);
                              } else {
                                _showQuantityDialog(product);
                              }
                            },
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          bool isPiece = product.unit.toLowerCase().contains('pc') || product.unit.toLowerCase().contains('piece');
                          if (isPiece) {
                            _addToCart(product);
                          } else {
                            _showQuantityDialog(product);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Add to Cart'),
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

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_cart.length} Items in Cart', style: const TextStyle(color: Colors.black54)),
              Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final List<Map<String, dynamic>> items = [];
              _cart.forEach((id, qty) {
                final p = _allProducts.firstWhere((element) => element.id == id);
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => InvoiceScreen(cartItems: items, total: _cartTotal),
              ));
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('Proceed to Bill'),
          ),
        ],
      ),
    );
  }
}
