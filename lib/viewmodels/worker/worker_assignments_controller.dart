import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/services/auth_service.dart';

class WorkerAssignmentsController extends GetxController {
  final storage = GetStorage();
  
  // Observables
  var isLoading = false.obs;
  var assignments = <dynamic>[].obs;
  var selectedFilter = 'assigned'.obs; // 'assigned', 'submitted', 'approved'
  
  // Submission Observables
  var isSubmitting = false.obs;
  var isLoadingInventory = false.obs;
  var inventoryAllocations = <dynamic>[].obs;
  
  // Controllers for dialog
  final outputQuantityController = TextEditingController();
  final rejectedQuantityController = TextEditingController();
  final notesController = TextEditingController();
  
  // Map to track return quantities: {allocationId: {returned: controller, broken: controller}}
  final Map<String, Map<String, TextEditingController>> returnControllers = {};

  @override
  void onInit() {
    super.onInit();
    fetchAssignments();
  }

  @override
  void onClose() {
    outputQuantityController.dispose();
    rejectedQuantityController.dispose();
    notesController.dispose();
    for (var map in returnControllers.values) {
      map.values.forEach((c) => c.dispose());
    }
    super.onClose();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMyAssignments(status: selectedFilter.value);
      
      if (response['success'] == true) {
        assignments.value = response['data'] ?? [];
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to load assignments');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load assignments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInventoryAllocations(String workOrderId, String stageId) async {
    isLoadingInventory.value = true;
    inventoryAllocations.clear();
    returnControllers.clear();
    
    try {
      final response = await ApiService.getStageInventoryAllocations(workOrderId, stageId);
      
      if (response['success'] == true) {
        final data = response['data'] as List;
        // Filter allocations for current worker
        final currentWorkerId = storage.read('user_id')?.toString();
        
        final workerAllocations = data.where((allocation) {
          final worker = allocation['worker_id'];
          final workerId = worker is Map ? worker['id']?.toString() : worker?.toString();
          return workerId == currentWorkerId;
        }).toList();

        inventoryAllocations.value = workerAllocations;

        // Initialize controllers for each allocation
        for (var allocation in workerAllocations) {
          final id = allocation['id'].toString();
          returnControllers[id] = {
            'returned': TextEditingController(text: '0'),
            'broken': TextEditingController(text: '0'),
          };
        }
      }
    } catch (e) {
      print('Error loading inventory: $e');
      // Don't show snackbar here to avoid spamming if it's just empty
    } finally {
      isLoadingInventory.value = false;
    }
  }

  Future<void> submitWork(String assignmentId) async {
    if (outputQuantityController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter output quantity');
      return;
    }

    isSubmitting.value = true;
    try {
      // 1. Submit the work assignment
      final workBody = {
        'output_quantity': int.tryParse(outputQuantityController.text) ?? 0,
        'rejected_quantity': int.tryParse(rejectedQuantityController.text) ?? 0,
        'notes': notesController.text,
      };

      final workResponse = await ApiService.submitWorkerAssignment(assignmentId, workBody);

      if (workResponse['success'] != true) {
        throw Exception(workResponse['message'] ?? 'Failed to submit work');
      }

      // 2. Submit inventory returns if any
      for (var allocation in inventoryAllocations) {
        final id = allocation['id'].toString();
        final controllers = returnControllers[id];
        
        if (controllers != null) {
          final returned = int.tryParse(controllers['returned']?.text ?? '0') ?? 0;
          final broken = int.tryParse(controllers['broken']?.text ?? '0') ?? 0;

          if (returned > 0 || broken > 0) {
            try {
              await ApiService.returnWorkerInventory(id, {
                'quantity_returned': returned,
                'quantity_broken_lost': broken,
                'notes': 'Returned via app',
              });
            } catch (e) {
              print('Failed to return inventory $id: $e');
              // Continue with other returns even if one fails
            }
          }
        }
      }

      Get.back(); // Close dialog
      Get.snackbar('Success', 'Work submitted successfully');
      fetchAssignments(); // Refresh list
      
      // Clear form
      outputQuantityController.clear();
      rejectedQuantityController.clear();
      notesController.clear();
      
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  void logout() {
    AuthService.logout();
  }
}
