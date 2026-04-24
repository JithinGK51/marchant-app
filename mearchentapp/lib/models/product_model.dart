class Product {
  final String id;
  final String name;
  final String categoryId;
  final double quantity;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double lowStockThreshold;
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.lowStockThreshold,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'] ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      costPrice: (json['cost_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      lowStockThreshold: (json['low_stock_threshold'] as num).toDouble(),
      categoryName: json['categories'] != null ? json['categories']['name'] : null,
    );
  }
}
