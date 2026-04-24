import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../core/theme.dart';
import 'add_product_screen.dart';
import 'category_management_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProducts();
      setState(() {
        _allProducts = data;
        _filteredProducts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _allProducts.where((p) => 
        p['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteProduct(id);
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Inventory 📦'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(child: Text(_searchQuery.isEmpty ? 'No products yet. Add your first product! 📦' : 'No products found'))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          itemCount: _filteredProducts.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final p = Product.fromJson(_filteredProducts[index]);
                            return _buildProductCard(context, p);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()));
          if (result == true) _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    bool isLowStock = product.quantity <= product.lowStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLowStock ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (isLowStock ? Colors.red : AppTheme.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, 
              color: isLowStock ? Colors.red : AppTheme.primaryColor
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                Text('Category: ${product.categoryName ?? "General"}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Text('${product.quantity} ${product.unit} left', 
                  style: TextStyle(
                    color: isLowStock ? Colors.red : AppTheme.primaryColor, 
                    fontWeight: FontWeight.w600,
                    fontSize: 13
                  )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${product.sellingPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddProductScreen(product: product))
                    );
                    if (result == true) _loadProducts();
                  } else if (value == 'delete') {
                    _deleteProduct(product.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
