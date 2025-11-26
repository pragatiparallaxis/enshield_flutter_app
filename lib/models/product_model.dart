class ProductModel {
  final String? id;
  final String name;
  final String? description;
  final double? price;
  final int? inventoryQuantity;
  final String? category;
  final String? status;

  ProductModel({
    this.id,
    required this.name,
    this.description,
    this.price,
    this.inventoryQuantity,
    this.category,
    this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      inventoryQuantity: json['inventory_quantity'],
      category: json['category'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'inventory_quantity': inventoryQuantity,
      'category': category,
      'status': status,
    };
  }
}
