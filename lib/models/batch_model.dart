import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/models/product_model.dart';

class BatchModel {
  final String? id;
  final String batchCode;
  final String? name;
  final String workOrderId;
  final String? productId;
  final int plannedQuantity;
  final String status;
  final String? assignedTo;
  final String? notes;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<SizeVariant>? sizeVariants;
  final List<PieceGroup>? pieceGroups;
  final List<BatchStageProgress>? stageProgress;
  final List<ProductPiece>? productPieces;
  final WorkOrder? workOrder;
  final ProductModel? product;

  BatchModel({
    this.id,
    required this.batchCode,
    this.name,
    required this.workOrderId,
    this.productId,
    required this.plannedQuantity,
    this.status = 'pending',
    this.assignedTo,
    this.notes,
    this.createdDate,
    this.updatedDate,
    this.startedAt,
    this.completedAt,
    this.sizeVariants,
    this.pieceGroups,
    this.stageProgress,
    this.productPieces,
    this.workOrder,
    this.product,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id']?.toString(),
      batchCode: json['batch_code'] ?? '',
      name: json['name'],
      workOrderId: json['work_order_id']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      plannedQuantity: json['planned_quantity'] is int ? json['planned_quantity'] : int.tryParse(json['planned_quantity']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      assignedTo: json['assigned_to'],
      notes: json['notes'],
      createdDate: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      updatedDate: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      sizeVariants: json['size_variants'] != null 
          ? (json['size_variants'] as List).map((v) => SizeVariant.fromJson(v)).toList()
          : null,
      pieceGroups: json['piece_groups'] != null 
          ? (json['piece_groups'] as List).map((g) => PieceGroup.fromJson(g)).toList()
          : null,
      stageProgress: json['stage_progress'] != null 
          ? (json['stage_progress'] as List).map((s) => BatchStageProgress.fromJson(s)).toList()
          : null,
      productPieces: json['product_pieces'] != null 
          ? (json['product_pieces'] as List).map((p) => ProductPiece.fromJson(p)).toList()
          : null,
      workOrder: json['work_order'] != null ? WorkOrder.fromJson(json['work_order']) : null,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_code': batchCode,
      'name': name,
      'work_order_id': workOrderId,
      'product_id': productId,
      'planned_quantity': plannedQuantity,
      'status': status,
      'assigned_to': assignedTo,
      'notes': notes,
      'date_created': createdDate?.toIso8601String(),
      'date_updated': updatedDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'size_variants': sizeVariants?.map((v) => v.toJson()).toList(),
      'piece_groups': pieceGroups?.map((g) => g.toJson()).toList(),
      'stage_progress': stageProgress?.map((s) => s.toJson()).toList(),
      'product_pieces': productPieces?.map((p) => p.toJson()).toList(),
    };
  }
}

class SizeVariant {
  final String? name;
  final String size;
  final int quantity;

  SizeVariant({
    this.name,
    required this.size,
    required this.quantity,
  });

  factory SizeVariant.fromJson(Map<String, dynamic> json) {
    return SizeVariant(
      name: json['name'],
      size: json['size'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'quantity': quantity,
    };
  }
}

class PieceGroup {
  final String name;
  final int quantity;

  PieceGroup({
    required this.name,
    required this.quantity,
  });

  factory PieceGroup.fromJson(Map<String, dynamic> json) {
    return PieceGroup(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}

class BatchStageProgress {
  final String? id;
  final String batchId;
  final String stageId;
  final String stageName;
  final int stageOrder;
  final int inputQuantity;
  final int outputQuantity;
  final int rejectedQuantity;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedTo;
  final String? assignedUser;
  final String? outsourcedVendorId;
  final String? outsourcedVendor;
  final String? completedBy;
  final String? completedByUser;
  final String? notes;
  final List<BatchStageProgressPiece>? pieces;

  BatchStageProgress({
    this.id,
    required this.batchId,
    required this.stageId,
    required this.stageName,
    required this.stageOrder,
    required this.inputQuantity,
    required this.outputQuantity,
    required this.rejectedQuantity,
    required this.status,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.assignedUser,
    this.outsourcedVendorId,
    this.outsourcedVendor,
    this.completedBy,
    this.completedByUser,
    this.notes,
    this.pieces,
  });

  factory BatchStageProgress.fromJson(Map<String, dynamic> json) {
    return BatchStageProgress(
      id: json['id']?.toString(),
      batchId: json['batch_id']?.toString() ?? '',
      stageId: json['stage_id']?.toString() ?? '',
      stageName: json['stage_name'] ?? '',
      stageOrder: json['stage_order'] ?? 0,
      inputQuantity: int.tryParse(json['input_quantity']?.toString() ?? '0') ?? 0,
      outputQuantity: int.tryParse(json['output_quantity']?.toString() ?? '0') ?? 0,
      rejectedQuantity: int.tryParse(json['rejected_quantity']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      assignedTo: json['assigned_to'] is String 
          ? json['assigned_to'] 
          : json['assigned_to']?['id']?.toString(),
      assignedUser: json['assigned_user'] != null && json['assigned_user'] is Map
          ? '${json['assigned_user']['first_name']} ${json['assigned_user']['last_name']}'
          : null,
      outsourcedVendorId: json['outsourced_vendor_id']?.toString(),
      outsourcedVendor: json['outsourced_vendor'] != null && json['outsourced_vendor'] is Map
          ? json['outsourced_vendor']['name']
          : null,
      completedBy: json['completed_by'] is String 
          ? json['completed_by'] 
          : json['completed_by']?['id']?.toString(),
      completedByUser: json['completed_by_user'] != null && json['completed_by_user'] is Map
          ? '${json['completed_by_user']['first_name']} ${json['completed_by_user']['last_name']}'
          : json['completed_by'] != null && json['completed_by'] is Map
              ? '${json['completed_by']['first_name']} ${json['completed_by']['last_name']}'
              : null,
      notes: json['notes'],
      pieces: json['pieces'] != null 
          ? (json['pieces'] as List).map((p) => BatchStageProgressPiece.fromJson(p)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'stage_id': stageId,
      'stage_name': stageName,
      'stage_order': stageOrder,
      'input_quantity': inputQuantity,
      'output_quantity': outputQuantity,
      'rejected_quantity': rejectedQuantity,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'outsourced_vendor_id': outsourcedVendorId,
      'completed_by': completedBy,
      'notes': notes,
    };
  }
}

class BatchStageProgressPiece {
  final String? id;
  final String progressId;
  final String pieceId;
  final int processedOutput;
  final int processedRejected;
  final String processedStatus;
  final String? notes;
  final bool isPaired;
  final String? pairedWithPieceId;
  final ProductPiece? piece;

  BatchStageProgressPiece({
    this.id,
    required this.progressId,
    required this.pieceId,
    required this.processedOutput,
    required this.processedRejected,
    required this.processedStatus,
    this.notes,
    this.isPaired = false,
    this.pairedWithPieceId,
    this.piece,
  });

  factory BatchStageProgressPiece.fromJson(Map<String, dynamic> json) {
    // Handle case where piece_id might be an object instead of string
    String pieceId;
    if (json['piece_id'] is Map) {
      // If piece_id is an object, extract the id field
      pieceId = json['piece_id']['id']?.toString() ?? '';
    } else {
      // If piece_id is a string, use it directly
      pieceId = json['piece_id']?.toString() ?? '';
    }
    
    return BatchStageProgressPiece(
      id: json['id']?.toString(),
      progressId: json['progress_id']?.toString() ?? '',
      pieceId: pieceId,
      processedOutput: int.tryParse(json['processed_output']?.toString() ?? '0') ?? 0,
      processedRejected: int.tryParse(json['processed_rejected']?.toString() ?? '0') ?? 0,
      processedStatus: json['processed_status'] ?? 'processed',
      notes: json['notes'],
      isPaired: json['is_paired'] ?? false,
      pairedWithPieceId: json['paired_with_piece_id']?.toString(),
      piece: json['piece'] != null ? ProductPiece.fromJson(json['piece']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'progress_id': progressId,
      'piece_id': pieceId,
      'processed_output': processedOutput,
      'processed_rejected': processedRejected,
      'processed_status': processedStatus,
      'notes': notes,
      'is_paired': isPaired,
      'paired_with_piece_id': pairedWithPieceId,
    };
  }
}

class ProductPiece {
  final String? id;
  final String batchId;
  final String? currentStageId;
  final String pieceCode;
  final String? name;
  final String size;
  final int? quantity;
  final String? componentProductId;
  final String? componentType;
  final String status;
  final List<Map<String, dynamic>> stageHistory;
  final String? productId;
  final ProductModel? product;

  ProductPiece({
    this.id,
    required this.batchId,
    this.currentStageId,
    required this.pieceCode,
    this.name,
    required this.size,
    this.quantity,
    this.componentProductId,
    this.componentType,
    this.status = 'active',
    this.stageHistory = const [],
    this.productId,
    this.product,
  });

  factory ProductPiece.fromJson(Map<String, dynamic> json) {
    return ProductPiece(
      id: json['id']?.toString(),
      batchId: json['batch_id']?.toString() ?? '',
      currentStageId: json['current_stage_id']?.toString(),
      pieceCode: json['piece_code'] ?? '',
      name: json['name'],
      size: json['size'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0'),
      componentProductId: json['component_product_id']?.toString(),
      componentType: json['component_type'],
      status: json['status'] ?? 'active',
      stageHistory: json['stage_history'] != null 
          ? List<Map<String, dynamic>>.from(json['stage_history'])
          : [],
      productId: json['product_id']?.toString(),
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'current_stage_id': currentStageId,
      'piece_code': pieceCode,
      'name': name,
      'size': size,
      'quantity': quantity,
      'component_product_id': componentProductId,
      'component_type': componentType,
      'status': status,
      'stage_history': stageHistory,
      'product_id': productId,
    };
  }
}
