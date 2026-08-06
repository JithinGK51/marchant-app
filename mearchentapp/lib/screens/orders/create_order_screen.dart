import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import 'invoice_screen.dart';
import '../notifications/notification_screen.dart';
import 'quick_scan_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<dynamic> _categories = [{'id': 'all', 'name': 'All'}];
  List<Product> _allProducts = [];
  final Map<String, double> _cart = {}; // product_id -> quantity
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategoryId = "all";
  bool _isSidebarMinimized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _enterQuickScanMode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickScanScreen(
          allProducts: _allProducts,
          initialCart: _cart,
        ),
      ),
    );

    if (result == true) {
      setState(() => _cart.clear());
    } else if (result is Map<String, double>) {
      setState(() => _cart.addAll(result));
    } else {
      _loadData(); // Refresh to sync any changes
    }
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.getCategories();
      final List<Product> prods = (await ApiService.getProducts()).map((e) => Product.fromJson(e)).toList();
      
      final newCategories = [{'id': 'all', 'name': 'All'}, ...cats];

      setState(() {
        _categories = newCategories;
        _allProducts = prods;
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
        leading: IconButton(
          icon: Icon(_isSidebarMinimized ? Icons.menu : Icons.menu_open),
          onPressed: () => setState(() => _isSidebarMinimized = !_isSidebarMinimized),
          tooltip: _isSidebarMinimized ? 'Expand Sidebar' : 'Minimize Sidebar',
        ),
        title: const Text('Create Order 🛒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
        bottom: _isLoading ? null : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
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
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Row(
            children: [
              _buildSidebar(),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: _buildProductGrid(_selectedCategoryId),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enterQuickScanMode,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.camera_alt_rounded),
      ),
      bottomNavigationBar: _cart.isEmpty ? null : _buildCartSummary(),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarMinimized ? 60 : 100,
      color: Colors.white,
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryId == cat['id'].toString();
          return InkWell(
            onTap: () => setState(() => _selectedCategoryId = cat['id'].toString()),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: _isSidebarMinimized ? 16 : 20,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    width: 4,
                  ),
                ),
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.folder_open : Icons.folder_outlined,
                    color: isSelected ? AppTheme.primaryColor : Colors.black54,
                    size: _isSidebarMinimized ? 24 : 20,
                  ),
                  if (!_isSidebarMinimized) ...[
                    const SizedBox(height: 4),
                    Text(
                      cat['name'],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
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
                          GestureDetector(
                            onTap: () => _showQuantityDialog(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cartQty % 1 == 0 ? cartQty.toInt().toString() : cartQty.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            onPressed: () {
                              _addToCart(product);
                            },
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _showQuantityDialog(product),
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
              Row(
                children: [
                  Text('${_cart.length} Items in Cart', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Order?'),
                          content: const Text('Are you sure you want to clear all items from the cart?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
                            TextButton(
                              onPressed: () {
                                setState(() => _cart.clear());
                                Navigator.pop(context);
                              },
                              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
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
              final result = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => InvoiceScreen(cartItems: items, total: _cartTotal),
              ));
              if (result == true) {
                setState(() => _cart.clear());
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('Proceed to Bill'),
          ),
        ],
      ),
    );
  }
}
