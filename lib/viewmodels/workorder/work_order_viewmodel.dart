import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/models/work_order_model.dart' hide Worker;
import 'package:enshield_app/models/work_order_model.dart' as models show Worker;
import 'package:enshield_app/services/api_service.dart';

class WorkOrderViewModel extends GetxController {
  final String workOrderId;
  WorkOrderViewModel(this.workOrderId);

  var workOrder = Rxn<WorkOrder>();
  var isLoading = true.obs;
  var categories = <WorkOrderCategory>[].obs;
  var sizes = <Size>[].obs;
  var workers = <models.Worker>[].obs;
  var inventoryItems = <InventoryItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Validate work order ID
    if (workOrderId.isEmpty || workOrderId.trim().isEmpty) {
      print("❌ Invalid work order ID: $workOrderId");
      Get.snackbar(
        "Error",
        "Invalid work order ID. Please select a valid work order.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      isLoading.value = false;
      return;
    }
    
    loadWorkOrderDetails();
    loadCategories();
    loadSizes();
    loadWorkers();
    loadInventoryItems();
  }

  /// Load Work Order Details from API
  Future<void> loadWorkOrderDetails() async {
    // Validate work order ID before making API call
    if (workOrderId.isEmpty || workOrderId.trim().isEmpty) {
      print("❌ Cannot load work order details: Invalid ID");
      return;
    }
    
    try {
      isLoading.value = true;
      print("📡 Fetching Work Order ID: $workOrderId");

      final response = await ApiService.getWorkOrderDetails(workOrderId);
      print("✅ Work Order Details Response: $response");

      if (response["success"] == true && response["data"] != null) {
        workOrder.value = WorkOrder.fromJson(response["data"]);
        print("✅ Work Order loaded successfully: ${workOrder.value?.title}");
      } else {
        print("❌ API returned error: ${response["message"]}");
        Get.snackbar("Error", "Failed to load work order details: ${response["message"]}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      print("❌ Error fetching work order: $e");
      Get.snackbar("Error", "Network error: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response["success"] == true && response["data"] != null) {
        var categoriesData = response["data"] as List;
        categories.value = categoriesData.map((item) => WorkOrderCategory.fromJson(item)).toList();
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
    }
  }

  /// Load sizes
  Future<void> loadSizes() async {
    try {
      final response = await ApiService.getSizes();
      if (response["success"] == true && response["data"] != null) {
        var sizesData = response["data"] as List;
        sizes.value = sizesData.map((item) => Size.fromJson(item)).toList();
      }
    } catch (e) {
      print("❌ Error fetching sizes: $e");
    }
  }

  /// Load workers
  Future<void> loadWorkers() async {
    try {
      final response = await ApiService.getWorkers();
      if (response["success"] == true && response["data"] != null) {
        var workersData = response["data"] as List;
        workers.value = workersData.map((item) => models.Worker.fromJson(item)).toList();
      }
    } catch (e) {
      print("❌ Error fetching workers: $e");
    }
  }

  /// Load inventory items
  Future<void> loadInventoryItems() async {
    try {
      final response = await ApiService.getInventoryItems();
      if (response["success"] == true && response["data"] != null) {
        var inventoryData = response["data"] as List;
        inventoryItems.value = inventoryData.map((item) => InventoryItem.fromJson(item)).toList();
      }
    } catch (e) {
      print("❌ Error fetching inventory items: $e");
    }
  }

  /// Allocate materials
  Future<bool> allocateMaterials(Map<String, dynamic> body) async {
    try {
      isLoading.value = true;
      final response = await ApiService.allocateMaterials(workOrderId, body);
      
      if (response["success"] == true) {
        await loadWorkOrderDetails();
        Get.snackbar("Success", "Materials allocated successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["message"] ?? "Failed to allocate materials",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete stage
  Future<bool> completeStage(Map<String, dynamic> body) async {
    try {
      isLoading.value = true;
      final response = await ApiService.completeStage(workOrderId, body);
      
      if (response["success"] == true) {
        await loadWorkOrderDetails();
        Get.snackbar("Success", "Stage completed successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["message"] ?? "Failed to complete stage",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create category
  Future<bool> createCategory(String name) async {
    try {
      final response = await ApiService.createCategory({'name': name});
      if (response["success"] == true) {
        await loadCategories();
        Get.snackbar("Success", "Category created successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["message"] ?? "Failed to create category",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  /// Create size
  Future<bool> createSize(String name, {String? description}) async {
    try {
      final body = {'name': name};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      final response = await ApiService.createSize(body);
      if (response["success"] == true) {
        await loadSizes();
        Get.snackbar("Success", "Size created successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["message"] ?? "Failed to create size",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  /// Return layers and recalculate quantities
  Future<bool> returnLayers(String inventoryId, int layersToReturn, {bool restockInventory = true}) async {
    try {
      isLoading.value = true;
      final response = await ApiService.returnLayers(inventoryId, {
        'layers_to_return': layersToReturn,
        'restock_inventory': restockInventory,
      });
      
      if (response["success"] == true) {
        await loadWorkOrderDetails();
        Get.snackbar("Success", response["message"] ?? "Layers returned successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["error"] ?? response["message"] ?? "Failed to return layers",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh work order data
  @override
  Future<void> refresh() async {
    await loadWorkOrderDetails();
  }

  void editWorkOrder() {
    Get.snackbar(
      "Edit Work Order",
      "Edit screen coming soon!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E1E2E),
      colorText: Colors.white,
    );
  }
  /// Update inventory allocation
  Future<bool> updateInventoryAllocation(String workOrderId, String inventoryId, Map<String, dynamic> body) async {
    try {
      isLoading.value = true;
      final response = await ApiService.updateAllocation(workOrderId, inventoryId, body);
      
      if (response["success"] == true) {
        await loadWorkOrderDetails();
        Get.snackbar("Success", "Allocation updated successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        return true;
      } else {
        Get.snackbar("Error", response["message"] ?? "Failed to update allocation",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
