class Product {
  final String id;
  final String name;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  Product copyWith({String? id, String? name, double? price, int? stock}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  // Convert to JSON for API (API uses productName)
  Map<String, dynamic> toJson() {
    return {'productName': name, 'price': price, 'stock': stock};
  }

  // Create from JSON response (API may return productName or name)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id:
          json['productId']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      name: json['productName'] ?? json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }
}
