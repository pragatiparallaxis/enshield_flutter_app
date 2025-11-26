class OutsourcedPartyModel {
  final String? id;
  final String name;
  final String serviceType;
  final String? contact;
  final double? rate;
  final String? notes;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  OutsourcedPartyModel({
    this.id,
    required this.name,
    required this.serviceType,
    this.contact,
    this.rate,
    this.notes,
    this.isActive = true,
    this.createdDate,
    this.updatedDate,
  });

  factory OutsourcedPartyModel.fromJson(Map<String, dynamic> json) {
    return OutsourcedPartyModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      serviceType: json['service_type'] ?? '',
      contact: json['contact'],
      rate: json['rate']?.toDouble(),
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdDate: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      updatedDate: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service_type': serviceType,
      'contact': contact,
      'rate': rate,
      'notes': notes,
      'is_active': isActive,
      'date_created': createdDate?.toIso8601String(),
      'date_updated': updatedDate?.toIso8601String(),
    };
  }
}
