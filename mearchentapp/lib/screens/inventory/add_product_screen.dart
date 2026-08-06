import 'package:flutter/material.dart';
import '../../widgets/barcode_scanner_widget.dart';
import '../../services/api_service.dart';

import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _sellingController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedUnit = 'KG';
  String? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _qtyController.text = widget.product!.quantity.toString();
      _costController.text = widget.product!.costPrice.toString();
      _sellingController.text = widget.product!.sellingPrice.toString();
      _selectedUnit = widget.product!.unit;
      _selectedCategoryId = widget.product!.categoryId;
      _barcodeController.text = widget.product!.barcode ?? '';
    }
    _loadCategories();
  }

  Future<void> _scanBarcode() async {
    var res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerWidget(),
        ));
    if (res is String && res != "-1") {
      if (!mounted) return;
      setState(() {
        _barcodeController.text = res;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategories();
      setState(() => _categories = data);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final productData = {
        "name": _nameController.text,
        "category_id": _selectedCategoryId,
        "quantity": double.tryParse(_qtyController.text) ?? 0,
        "unit": _selectedUnit,
        "cost_price": double.tryParse(_costController.text) ?? 0,
        "selling_price": double.tryParse(_sellingController.text) ?? 0,
        "low_stock_threshold": widget.product?.lowStockThreshold ?? 5.0,
        "barcode": _barcodeController.text.isEmpty ? null : _barcodeController.text,
      };

      if (widget.product != null) {
        await ApiService.updateProduct(widget.product!.id, productData);
      } else {
        await ApiService.createProduct(productData);
      }
      
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product != null ? 'Edit Product ✏️' : 'Add Product 📦')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Scan or enter barcode',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(
                value: c['id'].toString(), 
                child: Text(c['name'])
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: ['KG', 'L', 'Piece'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _selectedUnit = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost Price (₹)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _sellingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('Save Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
