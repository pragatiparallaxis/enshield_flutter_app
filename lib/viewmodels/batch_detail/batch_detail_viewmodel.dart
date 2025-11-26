import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:enshield_app/models/batch_model.dart';
import 'package:enshield_app/models/outsourced_party_model.dart';
import 'package:enshield_app/models/app_user_model.dart';
import 'package:enshield_app/models/production_stage_model.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/models/material_model.dart';


class BatchDetailViewModel extends GetxController {
  final String batchId;
  
  var batch = Rxn<BatchModel>();
  var stageProgress = <BatchStageProgress>[].obs;
  var productPieces = <ProductPiece>[].obs;
  var productionStages = <ProductionStageModel>[].obs;
  var outsourcedParties = <OutsourcedPartyModel>[].obs;
  var appUsers = <AppUserModel>[].obs;
  var isLoading = false.obs;
  var isActionLoading = false.obs;
  var materials = <MaterialModel>[].obs;

  // Stage completion data
  var inputQuantity = 0.obs;
  var outputQuantity = 0.obs;
  var rejectedQuantity = 0.obs;
  var notes = ''.obs;
  var outsourcedVendorId = Rxn<String>();
  var completedBy = ''.obs;
  var perPieces = <Map<String, dynamic>>[].obs;
  
  // Multi-worker distribution
  var workerAssignments = <Map<String, dynamic>>[].obs; // [{worker_id, worker_name, quantity}]

  // Expose available quantity per piece (from previous stage outputs or original qty)
  int getAvailableForPiece(String pieceId) {
    return _pieceAvailableQuantities[pieceId] ?? 0;
  }

  BatchDetailViewModel(this.batchId);

  @override
  void onInit() {
    super.onInit();
    loadBatchData();
    loadProductionStages();
    loadOutsourcedParties();
    loadAppUsers();
  }
/// Load materials for this batch
Future<void> loadMaterials() async {
  try {
    final response = await ApiService.get('/api/production/materials?batch_id=$batchId');
    if (response['success'] == true && response['data'] != null) {
      materials.value = (response['data'] as List)
          .map((item) => MaterialModel.fromJson(item))
          .toList();
    } else {
      materials.clear();
    }
  } catch (e) {
    print("Error loading materials: $e");
    materials.clear();
  }
}

  /// Load batch data and related information
  Future<void> loadBatchData() async {
    try {
      isLoading.value = true;
      
      // Load batch details
     try {
  final batchResponse = await ApiService.getBatch(batchId);
  if (batchResponse['success'] == true && batchResponse['data'] != null) {
    batch.value = BatchModel.fromJson(batchResponse['data']);
  }
  await loadMaterials(); // 👈 moved inside try, before catch
} catch (e) {
  print('Error loading batch details: $e');
  rethrow;
}


      // Load stage progress
      try {
        final progressResponse = await ApiService.getBatchStageProgressByBatch(batchId);
        if (progressResponse['success'] == true && progressResponse['data'] != null) {
          final progressList = (progressResponse['data'] as List)
              .map((item) {
                try {
                  return BatchStageProgress.fromJson(item);
                } catch (e) {
                  print('Error parsing stage progress item: $e');
                  print('Item data: $item');
                  rethrow;
                }
              })
              .toList();
        
        // Populate stage names from production stages
        for (var progress in progressList) {
          print('Processing stage progress: ${progress.stageId} - Input: ${progress.inputQuantity}, Output: ${progress.outputQuantity}, Rejected: ${progress.rejectedQuantity}, Status: ${progress.status}');
          
          final stage = productionStages.firstWhereOrNull(
            (s) => s.id == progress.stageId,
          );
          if (stage != null) {
            // Create a new progress object with the stage name
            final updatedProgress = BatchStageProgress(
              id: progress.id,
              batchId: progress.batchId,
              stageId: progress.stageId,
              stageName: stage.name,
              stageOrder: stage.stageOrder,
              inputQuantity: progress.inputQuantity,
              outputQuantity: progress.outputQuantity,
              rejectedQuantity: progress.rejectedQuantity,
              status: progress.status,
              startDate: progress.startDate,
              endDate: progress.endDate,
              assignedTo: progress.assignedTo,
              assignedUser: progress.assignedUser,
              outsourcedVendorId: progress.outsourcedVendorId,
              outsourcedVendor: progress.outsourcedVendor,
              completedBy: progress.completedBy,
              completedByUser: progress.completedByUser,
              notes: progress.notes,
              pieces: progress.pieces,
            );
            final index = progressList.indexOf(progress);
            progressList[index] = updatedProgress;
          }
        }
          
          stageProgress.value = progressList;
        }
      } catch (e) {
        print('Error loading stage progress: $e');
        rethrow;
      }

      // Load product pieces
      try {
        final piecesResponse = await ApiService.getProductPieces(batchId);
        if (piecesResponse['success'] == true && piecesResponse['data'] != null) {
          productPieces.value = (piecesResponse['data'] as List)
              .map((item) {
                try {
                  return ProductPiece.fromJson(item);
                } catch (e) {
                  print('Error parsing product piece item: $e');
                  print('Item data: $item');
                  rethrow;
                }
              })
              .toList();
        }
      } catch (e) {
        print('Error loading product pieces: $e');
        rethrow;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load batch data: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load outsourced parties
  Future<void> loadOutsourcedParties() async {
    try {
      final response = await ApiService.getOutsourcedParties();
      if (response['success'] == true && response['data'] != null) {
        outsourcedParties.value = (response['data'] as List)
            .map((item) => OutsourcedPartyModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      print("Error loading outsourced parties: $e");
    }
  }

  /// Load app users
  Future<void> loadAppUsers() async {
    try {
      final response = await ApiService.getAppUsers();
      if (response['success'] == true && response['data'] != null) {
        appUsers.value = (response['data'] as List)
            .map((item) => AppUserModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      print("Error loading app users: $e");
    }
  }

  /// Load production stages
  Future<void> loadProductionStages() async {
    try {
      final response = await ApiService.getProductionStages();
      if (response['success'] == true && response['data'] != null) {
        productionStages.value = (response['data'] as List)
            .map((item) => ProductionStageModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      print("Error loading production stages: $e");
    }
  }


  /// Move batch to next stage
  Future<void> moveToNextStage({
    required String currentStageId,
    required int outputQuantity,
    required int rejectedQuantity,
    String? notes,
    String? outsourcedVendorId,
    String? completedBy,
    List<Map<String, dynamic>>? perPieces,
  }) async {
    try {
      isActionLoading.value = true;
      
      final body = {
        'currentStageId': currentStageId,
        'outputQuantity': outputQuantity,
        'rejectedQuantity': rejectedQuantity,
        'notes': notes,
        'outsourcedVendorId': outsourcedVendorId,
        'completedBy': completedBy,
        if (perPieces != null) 'perPieces': perPieces,
      };

      final response = await ApiService.moveBatchToNextStage(batchId, body);
      
      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "Stage completed successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        await loadBatchData(); // Refresh data
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Failed to complete stage",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to complete stage: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Get current stage progress
  BatchStageProgress? getCurrentStage() {
    return stageProgress.firstWhereOrNull((stage) => stage.status == 'in_progress');
  }

  /// Get next stage progress
  BatchStageProgress? getNextStage() {
    final currentStage = getCurrentStage();
    if (currentStage == null) return null;
    
    return stageProgress.firstWhereOrNull(
      (stage) => stage.stageOrder == currentStage.stageOrder + 1,
    );
  }

  /// Get pending stages
  List<BatchStageProgress> getPendingStages() {
    return stageProgress.where((stage) => stage.status == 'pending').toList();
  }

  /// Get final output quantity from the last completed stage
  int getFinalOutputQuantity() {
    final completedStages = getCompletedStages();
    if (completedStages.isEmpty) return 0;
    
    // Sort by stage order to get the last completed stage
    completedStages.sort((a, b) => (a.stageOrder ?? 0).compareTo(b.stageOrder ?? 0));
    final lastStage = completedStages.last;
    
    return lastStage.outputQuantity ?? 0;
  }

  /// Get completed stages
  List<BatchStageProgress> getCompletedStages() {
    return stageProgress.where((stage) => stage.status == 'completed').toList();
  }

  /// Start a specific stage
  Future<void> startStage(String stageId) async {
    try {
      isActionLoading.value = true;
      final response = await ApiService.startStage(batchId, stageId);
      
      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "Stage started successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        await loadBatchData(); // Refresh data
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Failed to start stage",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to start stage: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Store available quantities for each piece (max they can process)
  var _pieceAvailableQuantities = <String, int>{};

  /// Initialize stage completion data
  Future<void> initializeStageCompletion(BatchStageProgress stage) async {
    // Get pieces for this batch
    final pieces = productPieces.where((p) => p.batchId == stage.batchId).toList();
    
    // Find the previous completed stage to get actual available quantities per piece
    final prevStage = stageProgress
        .where((s) => s.status == 'completed' && (s.stageOrder ?? 999) < (stage.stageOrder ?? 999))
        .toList()
      ..sort((a, b) => (b.stageOrder ?? 0).compareTo(a.stageOrder ?? 0));
    final mostRecentPrevStage = prevStage.isNotEmpty ? prevStage.first : null;
    
    // Use previous stage's per-piece processed_output if available, otherwise use original piece quantity
    final pieceQuantities = <String, int>{};
    
    if (mostRecentPrevStage?.pieces != null && mostRecentPrevStage!.pieces!.isNotEmpty) {
      // Use previous stage's processed_output values
      for (var prevPiece in mostRecentPrevStage.pieces!) {
        final pieceId = prevPiece.pieceId.toString();
        pieceQuantities[pieceId] = prevPiece.processedOutput;
      }
      
      // For any pieces not in the previous stage's data, use their original quantity
      for (var piece in pieces) {
        final pieceId = piece.id.toString();
        if (!pieceQuantities.containsKey(pieceId)) {
          pieceQuantities[pieceId] = piece.quantity ?? 0;
        }
      }
    } else {
      // No previous stage data, use original piece quantities
      for (var piece in pieces) {
        final pieceId = piece.id.toString();
        pieceQuantities[pieceId] = piece.quantity ?? 0;
      }
    }
    
    // Store available quantities for updates
    _pieceAvailableQuantities = pieceQuantities;
    
    // Calculate actual stage input quantity
    // If we have previous stage data, use the sum of previous outputs
    // Otherwise, use the planned stage input quantity
    int stageInput;
    if (mostRecentPrevStage?.pieces != null && mostRecentPrevStage!.pieces!.isNotEmpty) {
      // Calculate total output from previous stage
      stageInput = mostRecentPrevStage!.pieces!.fold<int>(0, (sum, piece) => sum + piece.processedOutput);
    } else {
      // No previous stage, use planned input quantity
      stageInput = stage.inputQuantity;
    }
    inputQuantity.value = stageInput;
    
    // Create initial per-piece data
    final initialPerPieces = <Map<String, dynamic>>[];
    int totalOutput = 0;
    
    if (pieces.isNotEmpty) {
      // Use the actual output quantities from previous stage if available
      // Otherwise, distribute stage input proportionally to piece quantities
      
      // Check if we have previous stage data
      final hasPreviousData = mostRecentPrevStage?.pieces != null && mostRecentPrevStage!.pieces!.isNotEmpty;
      
      if (hasPreviousData) {
        // Use the exact output quantities from the previous stage
        for (var piece in pieces) {
          final pieceId = piece.id.toString();
          final previousOutput = pieceQuantities[pieceId] ?? 0;
          
          initialPerPieces.add({
            'piece_id': piece.id,
            'processed_output': previousOutput,
            'processed_rejected': 0,
            'processed_status': 'processed',
            'notes': '',
            'is_paired': false,
            'paired_with_piece_id': null,
          });
        }
      } else {
        // No previous stage - distribute stage input proportionally based on piece quantities
        int totalAvailable = 0;
        for (var piece in pieces) {
          totalAvailable += pieceQuantities[piece.id.toString()] ?? 0;
        }
        
        for (var piece in pieces) {
          final availableQty = pieceQuantities[piece.id.toString()] ?? 0;
          
          int scaledOutput;
          if (totalAvailable > 0 && stageInput > 0) {
            final ratio = availableQty / totalAvailable;
            scaledOutput = (stageInput * ratio).floor();
          } else {
            scaledOutput = availableQty;
          }
          
          initialPerPieces.add({
            'piece_id': piece.id,
            'processed_output': scaledOutput,
            'processed_rejected': 0,
            'processed_status': 'processed',
            'notes': '',
            'is_paired': false,
            'paired_with_piece_id': null,
          });
        }
        
        // Adjust the last piece to hit exact stage input
        if (initialPerPieces.isNotEmpty) {
          final currentSum = initialPerPieces.fold<int>(0, (sum, p) => sum + (p['processed_output'] as int? ?? 0));
          final delta = stageInput - currentSum;
          if (delta != 0) {
            final lastIdx = initialPerPieces.length - 1;
            final lastPiece = pieces[lastIdx];
            final lastAvailable = pieceQuantities[lastPiece.id.toString()] ?? 0;
            final adjusted = ((initialPerPieces[lastIdx]['processed_output'] as int) + delta).clamp(0, lastAvailable);
            initialPerPieces[lastIdx]['processed_output'] = adjusted;
          }
        }
      }
      
      totalOutput = initialPerPieces.fold<int>(0, (sum, p) => sum + (p['processed_output'] as int? ?? 0));
    }

    perPieces.value = initialPerPieces;
    outputQuantity.value = totalOutput;
    rejectedQuantity.value = 0;
    notes.value = stage.notes ?? '';
    outsourcedVendorId.value = stage.outsourcedVendorId;
    completedBy.value = stage.completedBy ?? '';
    workerAssignments.clear(); // Clear worker assignments when initializing new stage
  }

  /// Update rejected quantity
  void updateRejectedQuantity(int value) {
    rejectedQuantity.value = value;
  }

  /// Update outsourced vendor
  void updateOutsourcedVendor(String? value) {
    outsourcedVendorId.value = value;
  }

  /// Update completed by
  void updateCompletedBy(String value) {
    completedBy.value = value;
  }

  /// Update notes
  void updateNotes(String value) {
    notes.value = value;
  }

  /// Update per-piece output
  void updatePerPieceOutput(int index, int value) {
    final currentPiece = perPieces[index];
    final pieceId = currentPiece['piece_id'].toString();
    final availableQty = _pieceAvailableQuantities[pieceId] ?? 0;

    int newOutput = value.clamp(0, availableQty);
    int newRejected = availableQty - newOutput;

    perPieces[index]['processed_output'] = newOutput;
    perPieces[index]['processed_rejected'] = newRejected;
    _updateTotalQuantities();
  }

  /// Update per-piece rejected
  void updatePerPieceRejected(int index, int value) {
    final currentPiece = perPieces[index];
    final pieceId = currentPiece['piece_id'].toString();
    final availableQty = _pieceAvailableQuantities[pieceId] ?? 0;

    int newRejected = value.clamp(0, availableQty);
    int newOutput = availableQty - newRejected;

    perPieces[index]['processed_output'] = newOutput;
    perPieces[index]['processed_rejected'] = newRejected;
    _updateTotalQuantities();
  }

  /// Update total quantities
  void _updateTotalQuantities() {
    int totalOutput = 0;
    int totalRejected = 0;
    for (var pieceData in perPieces.value) {
      totalOutput += (pieceData['processed_output'] as int? ?? 0);
      totalRejected += (pieceData['processed_rejected'] as int? ?? 0);
    }
    outputQuantity.value = totalOutput;
    rejectedQuantity.value = totalRejected;
  }

  /// Add worker assignment
  void addWorkerAssignment(String workerId, String workerName, int quantity) {
    workerAssignments.add({
      'worker_id': workerId,
      'worker_name': workerName,
      'quantity': quantity,
    });
  }

  /// Update worker assignment quantity
  void updateWorkerAssignmentQuantity(int index, int quantity) {
    if (index >= 0 && index < workerAssignments.length) {
      workerAssignments[index]['quantity'] = quantity;
    }
  }

  /// Remove worker assignment
  void removeWorkerAssignment(int index) {
    if (index >= 0 && index < workerAssignments.length) {
      workerAssignments.removeAt(index);
    }
  }

  /// Get total assigned quantity
  int getTotalAssignedQuantity() {
    return workerAssignments.fold<int>(0, (sum, wa) => sum + (wa['quantity'] as int? ?? 0));
  }

  /// Get remaining quantity to assign
  int getRemainingQuantityToAssign() {
    return outputQuantity.value - getTotalAssignedQuantity();
  }

  /// Complete stage
  Future<void> completeStage(BatchStageProgress stage) async {
    try {
      isActionLoading.value = true;
      
      final body = {
        'currentStageId': stage.stageId,
        'outputQuantity': outputQuantity.value,
        'rejectedQuantity': rejectedQuantity.value,
        'notes': notes.value,
        'outsourcedVendorId': outsourcedVendorId.value,
        'completedBy': completedBy.value,
        'perPieces': perPieces.value.map((p) => {
          'piece_id': p['piece_id'],
          'processed_output': p['processed_output'],
          'processed_rejected': p['processed_rejected'],
          'processed_status': p['processed_status'],
          'notes': p['notes'],
          'is_paired': p['is_paired'],
          'paired_with_piece_id': p['paired_with_piece_id'],
        }).toList(),
        'workerAssignments': workerAssignments.value.map((wa) => {
          'worker_id': wa['worker_id'],
          'worker_name': wa['worker_name'],
          'quantity': wa['quantity'],
        }).toList(),
      };

      final response = await ApiService.moveBatchToNextStage(batchId, body);
      
      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "Stage completed successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        await loadBatchData(); // Refresh data
        
        // Check if batch is completed and update work order status
        await _checkAndUpdateWorkOrderStatus();
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Failed to complete stage",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to complete stage: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Start batch processing
  Future<void> startBatch() async {
    try {
      isActionLoading.value = true;
      
      final response = await ApiService.startBatchProcessing(batchId);
      
      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "Batch started successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        await loadBatchData(); // Refresh data
        
        // Update work order status to in_progress
        await _updateWorkOrderStatus('in_progress');
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Failed to start batch",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to start batch: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Check and update work order status based on batch completion
  Future<void> _checkAndUpdateWorkOrderStatus() async {
    try {
      if (batch.value?.workOrderId != null) {
        // Check if all batches for this work order are completed
        final batchesResponse = await ApiService.getBatchesByWorkOrder(batch.value!.workOrderId!);
        
        if (batchesResponse['success'] == true && batchesResponse['data'] != null) {
          final batches = (batchesResponse['data'] as List)
              .map((b) => BatchModel.fromJson(b))
              .toList();
          
          // Check if all batches are completed
          final allCompleted = batches.every((b) => b.status == 'completed');
          
          if (allCompleted && batches.isNotEmpty) {
            await _updateWorkOrderStatus('completed');
          }
        }
      }
    } catch (e) {
      print('Error checking work order status: $e');
    }
  }

  /// Update work order status
  Future<void> _updateWorkOrderStatus(String status) async {
    try {
      if (batch.value?.workOrderId != null) {
        final response = await ApiService.updateWorkOrderStatus(batch.value!.workOrderId!, status);
        
        if (response['success'] == true) {
          print('Work order status updated to: $status');
        }
      }
    } catch (e) {
      print('Error updating work order status: $e');
    }
  }
}
