class ProductionStageModel {
  final String? id;
  final String name;
  final String? description;
  final int stageOrder;
  final bool isOutsourced;

  ProductionStageModel({
    this.id,
    required this.name,
    this.description,
    required this.stageOrder,
    required this.isOutsourced,
  });

  factory ProductionStageModel.fromJson(Map<String, dynamic> json) {
    return ProductionStageModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      stageOrder: json['stage_order'] ?? 0,
      isOutsourced: json['is_outsourced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stage_order': stageOrder,
      'is_outsourced': isOutsourced,
    };
  }
}
