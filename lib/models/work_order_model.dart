import 'dart:convert';

// Work Order Models
class WorkOrder {
  final String id;
  final String work_order_code;
  final String title;
  final int planned_quantity;
  final String? client_name;
  final DateTime? order_date;
  final String status;
  final String? notes;
  final DateTime? date_created;
  final DateTime? date_updated;
  final List<WorkOrderItem> work_order_items;
  final List<WorkOrderStage> stages;
  final List<WorkOrderInventory> inventory;

  WorkOrder({
    required this.id,
    required this.work_order_code,
    required this.title,
    required this.planned_quantity,
    this.client_name,
    this.order_date,
    required this.status,
    this.notes,
    this.date_created,
    this.date_updated,
    this.work_order_items = const [],
    this.stages = const [],
    this.inventory = const [],
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id']?.toString() ?? '',
      work_order_code: json['work_order_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      planned_quantity: _parseInt(json['planned_quantity']),
      client_name: json['client_name']?.toString(),
      order_date: json['order_date'] != null ? DateTime.tryParse(json['order_date'].toString()) : null,
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      date_created: json['date_created'] != null ? DateTime.tryParse(json['date_created'].toString()) : null,
      date_updated: json['date_updated'] != null ? DateTime.tryParse(json['date_updated'].toString()) : null,
      work_order_items: (json['work_order_items'] as List?)
          ?.map((item) => WorkOrderItem.fromJson(item))
          .toList() ?? [],
      stages: (json['stages'] as List?)
          ?.map((stage) => WorkOrderStage.fromJson(stage))
          .toList() ?? [],
      inventory: (json['inventory'] as List?)
          ?.map((item) => WorkOrderInventory.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_code': work_order_code,
      'title': title,
      'planned_quantity': planned_quantity,
      'client_name': client_name,
      'order_date': order_date?.toIso8601String(),
      'status': status,
      'notes': notes,
      'date_created': date_created?.toIso8601String(),
      'date_updated': date_updated?.toIso8601String(),
      'work_order_items': work_order_items.map((item) => item.toJson()).toList(),
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'inventory': inventory.map((item) => item.toJson()).toList(),
    };
  }
}

class WorkOrderItem {
  final int id;
  final WorkOrderCategory? category;
  final String color;
  final Size? size;
  final int quantity;
  final List<WorkOrderStage>? work_order_stages;

  WorkOrderItem({
    required this.id,
    this.category,
    required this.color,
    this.size,
    required this.quantity,
    this.work_order_stages,
  });

  factory WorkOrderItem.fromJson(Map<String, dynamic> json) {
    return WorkOrderItem(
      id: _parseInt(json['id']),
      category: json['category_id'] is Map 
          ? WorkOrderCategory.fromJson(json['category_id']) 
          : (json['category'] is Map ? WorkOrderCategory.fromJson(json['category']) : null),
      color: json['color']?.toString() ?? '',
      size: json['size_id'] is Map 
          ? Size.fromJson(json['size_id']) 
          : (json['size'] is Map ? Size.fromJson(json['size']) : null),
      quantity: _parseInt(json['quantity']),
      work_order_stages: (json['work_order_stages'] as List?)
          ?.map((item) => WorkOrderStage.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': category?.toJson(),
      'color': color,
      'size_id': size?.toJson(),
      'quantity': quantity,
      'work_order_stages': work_order_stages?.map((item) => item.toJson()).toList(),
    };
  }
}

class WorkOrderStage {
  final int id;
  final String stage_name;
  final int stage_order;
  final int input_quantity;
  final int output_quantity;
  final int rejected_quantity;
  final String status;
  final String? notes;
  final List<WorkerAssignment>? worker_assignments;

  WorkOrderStage({
    required this.id,
    required this.stage_name,
    required this.stage_order,
    required this.input_quantity,
    required this.output_quantity,
    required this.rejected_quantity,
    required this.status,
    this.notes,
    this.worker_assignments,
  });

  factory WorkOrderStage.fromJson(Map<String, dynamic> json) {
    return WorkOrderStage(
      id: _parseInt(json['id']),
      stage_name: json['stage_name']?.toString() ?? '',
      stage_order: _parseInt(json['stage_order']),
      input_quantity: _parseInt(json['input_quantity']),
      output_quantity: _parseInt(json['output_quantity']),
      rejected_quantity: _parseInt(json['rejected_quantity']),
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      worker_assignments: (json['worker_assignments'] as List?)
          ?.map((a) => WorkerAssignment.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stage_name': stage_name,
      'stage_order': stage_order,
      'input_quantity': input_quantity,
      'output_quantity': output_quantity,
      'rejected_quantity': rejected_quantity,
      'status': status,
      'notes': notes,
      'worker_assignments': worker_assignments?.map((a) => a.toJson()).toList(),
    };
  }
}

class WorkerAssignment {
  final int id;
  final int work_order_stages_id;
  final dynamic workers_id; // Can be ID or object
  final Worker? worker; // Populated if workerId is object
  final int quantity;
  final String status;
  final int worker_output_quantity;
  final int admin_approved_quantity;
  final String? worker_notes;
  final String? admin_notes;

  WorkerAssignment({
    required this.id,
    required this.work_order_stages_id,
    required this.workers_id,
    this.worker,
    required this.quantity,
    required this.status,
    required this.worker_output_quantity,
    required this.admin_approved_quantity,
    this.worker_notes,
    this.admin_notes,
  });

  factory WorkerAssignment.fromJson(Map<String, dynamic> json) {
    Worker? workerObj;
    dynamic wId = json['workers_id'];
    
    if (wId is Map<String, dynamic>) {
      workerObj = Worker.fromJson(wId);
      wId = workerObj.id; // ID is now a String (UUID)
    } else if (wId != null) {
      // If it's not an object, convert to string
      wId = wId.toString();
    }

    return WorkerAssignment(
      id: _parseInt(json['id']),
      work_order_stages_id: _parseInt(json['work_order_stages_id']),
      workers_id: wId,
      worker: workerObj,
      quantity: _parseInt(json['quantity']),
      status: json['status']?.toString() ?? 'assigned',
      worker_output_quantity: _parseInt(json['worker_output_quantity']),
      admin_approved_quantity: _parseInt(json['admin_approved_quantity']),
      worker_notes: json['worker_notes']?.toString(),
      admin_notes: json['admin_notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_stages_id': work_order_stages_id,
      'workers_id': workers_id,
      'quantity': quantity,
      'status': status,
      'worker_output_quantity': worker_output_quantity,
      'admin_approved_quantity': admin_approved_quantity,
      'worker_notes': worker_notes,
      'admin_notes': admin_notes,
    };
  }
}

class Worker {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool is_active;
  final bool is_outsourced;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.is_active,
    required this.is_outsourced,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      is_active: _parseBool(json['is_active']),
      is_outsourced: _parseBool(json['is_outsourced']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'is_active': is_active,
      'is_outsourced': is_outsourced,
    };
  }
}

class WorkOrderInventory {
  final int id;
  final InventoryItem? inventoryItem;
  final String? color;
  final String? fabric;
  final double total_meters;
  final double table_length;
  final double? layers_calculated;
  final int? layers_used;
  final double? layers_returned;
  final int? pairs_per_layer;
  final int? output_quantity;
  final double? ratio_per_piece;
  final String? notes;
  final List<WorkOrderItem>? work_order_items;
  final List<WorkOrderCategory>? categories;
  final List<Size>? sizes;
  final DateTime? date_created;
  final DateTime? date_updated;

  WorkOrderInventory({
    required this.id,
    this.inventoryItem,
    this.color,
    this.fabric,
    required this.total_meters,
    required this.table_length,
    this.layers_calculated,
    this.layers_used,
    this.layers_returned,
    this.pairs_per_layer,
    this.output_quantity,
    this.ratio_per_piece,
    this.notes,
    this.work_order_items,
    this.categories,
    this.sizes,
    this.date_created,
    this.date_updated,
  });

  factory WorkOrderInventory.fromJson(Map<String, dynamic> json) {
    return WorkOrderInventory(
      id: _parseInt(json['id']),
      inventoryItem: json['inventory_id'] is Map 
          ? InventoryItem.fromJson(json['inventory_id']) 
          : null,
      color: json['color']?.toString(),
      fabric: json['fabric']?.toString(),
      total_meters: _parseDouble(json['total_meters']),
      table_length: _parseDouble(json['table_length']),
      layers_calculated: _parseDouble(json['layers_calculated']),
      layers_used: _parseInt(json['layers_used']),
      layers_returned: _parseDouble(json['layers_returned']),
      pairs_per_layer: _parseInt(json['pairs_per_layer']),
      output_quantity: _parseInt(json['output_quantity']),
      ratio_per_piece: _parseDouble(json['ratio_per_piece']),
      notes: json['notes']?.toString(),
      work_order_items: (json['work_order_items'] as List?)
          ?.map((item) => WorkOrderItem.fromJson(item))
          .toList(),
      categories: (json['categories'] as List?)
          ?.map((item) => WorkOrderCategory.fromJson(item))
          .toList(),
      sizes: (json['sizes'] as List?)
          ?.map((item) => Size.fromJson(item))
          .toList(),
      date_created: json['date_created'] != null ? DateTime.tryParse(json['date_created'].toString()) : null,
      date_updated: json['date_updated'] != null ? DateTime.tryParse(json['date_updated'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryItem?.toJson(),
      'color': color,
      'fabric': fabric,
      'total_meters': total_meters,
      'table_length': table_length,
      'layers_calculated': layers_calculated,
      'layers_used': layers_used,
      'layers_returned': layers_returned,
      'pairs_per_layer': pairs_per_layer,
      'output_quantity': output_quantity,
      'ratio_per_piece': ratio_per_piece,
      'notes': notes,
      'work_order_items': work_order_items?.map((item) => item.toJson()).toList(),
      'categories': categories?.map((item) => item.toJson()).toList(),
      'sizes': sizes?.map((item) => item.toJson()).toList(),
      'date_created': date_created?.toIso8601String(),
      'date_updated': date_updated?.toIso8601String(),
    };
  }
}

class WorkOrderCategory {
  final String id;
  final String name;
  final bool is_active;

  WorkOrderCategory({
    required this.id,
    required this.name,
    required this.is_active,
  });

  factory WorkOrderCategory.fromJson(Map<String, dynamic> json) {
    return WorkOrderCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      is_active: _parseBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': is_active,
    };
  }
}

class Size {
  final String id;
  final String name;
  final String? description;
  final bool is_active;

  Size({
    required this.id,
    required this.name,
    this.description,
    required this.is_active,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      is_active: _parseBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': is_active,
    };
  }
}

class InventoryItem {
  final String id;
  final String name;
  final double total;
  final double available;
  final double taken_quantity;
  final String? fabric;
  final String? color;
  final String? unit;
  final DateTime? date_created;
  final DateTime? date_updated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.total,
    required this.available,
    required this.taken_quantity,
    this.fabric,
    this.color,
    this.unit,
    this.date_created,
    this.date_updated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      total: _parseDouble(json['total']),
      available: _parseDouble(json['available']),
      taken_quantity: _parseDouble(json['taken_quantity']),
      fabric: json['fabric']?.toString(),
      color: json['color']?.toString(),
      unit: json['unit']?.toString(),
      date_created: json['date_created'] != null ? DateTime.tryParse(json['date_created'].toString()) : null,
      date_updated: json['date_updated'] != null ? DateTime.tryParse(json['date_updated'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total': total,
      'available': available,
      'taken_quantity': taken_quantity,
      'fabric': fabric,
      'color': color,
      'unit': unit,
      'date_created': date_created?.toIso8601String(),
      'date_updated': date_updated?.toIso8601String(),
    };
  }
}

// Helper functions for safe parsing
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final str = value.toString().toLowerCase();
  return str == 'true' || str == '1' || str == 'yes';
}
