class AppUserModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? role;
  final String? department;
  final String status;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  AppUserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.role,
    this.department,
    this.status = 'active',
    this.createdDate,
    this.updatedDate,
  });

  String get fullName => '$firstName $lastName';

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    // Handle role as either string or list
    String? role;
    if (json['role'] != null) {
      if (json['role'] is List) {
        role = (json['role'] as List).isNotEmpty ? json['role'][0].toString() : null;
      } else {
        role = json['role'].toString();
      }
    }
    
    return AppUserModel(
      id: json['id']?.toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: role,
      department: json['department'],
      status: json['is_active'] == true ? 'active' : 'inactive',
      createdDate: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      updatedDate: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'status': status,
      'date_created': createdDate?.toIso8601String(),
      'date_updated': updatedDate?.toIso8601String(),
    };
  }
}
