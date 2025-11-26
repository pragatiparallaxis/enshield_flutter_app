class MaterialModel {
  final String id;
  final String? name;
  final double? ratioPerPiece;
  final double? takenQuantity;
  final double? available;
  final double? total;
  final String? notes;

  MaterialModel({
    required this.id,
    this.name,
    this.ratioPerPiece,
    this.takenQuantity,
    this.available,
    this.total,
    this.notes,
  });

factory MaterialModel.fromJson(Map<String, dynamic> json) {
  final inventory = json['inventory'] ?? {};

  double? _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  return MaterialModel(
    id: json['id']?.toString() ?? '',
    name: inventory['name'] ?? 'Unnamed',
    ratioPerPiece: _toDouble(json['ratio_per_piece']),
    takenQuantity: _toDouble(inventory['taken_quantity']),
    available: _toDouble(inventory['available']),
    total: _toDouble(inventory['total']),
    notes: json['notes'],
  );

}}
