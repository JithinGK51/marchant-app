class OrderModel {
  final String id;
  final double subtotal;
  final double discount;
  final double finalAmount;
  final double profit;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.subtotal,
    required this.discount,
    required this.finalAmount,
    required this.profit,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      finalAmount: (json['final_amount'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      items: (json['order_items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final double quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String? productName;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    this.productName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      quantity: (json['quantity'] as num).toDouble(),
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      productName: json['products']?['name'],
    );
  }
}
