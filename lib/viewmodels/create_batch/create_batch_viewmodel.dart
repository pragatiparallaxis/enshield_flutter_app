import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/views/work_order_view.dart';

class CreateBatchViewModel extends GetxController {
  final batchCodeController = TextEditingController(text: "BATCH-001");
  final quantityController = TextEditingController(text: "0");
  final sizeNameController = TextEditingController();
  final sizeController = TextEditingController();
  final sizeQuantityController = TextEditingController();
  final notesController = TextEditingController();

  var sizeList = <Map<String, dynamic>>[].obs; // store both size + qty
  var isLoading = false.obs;

  var workOrders = <Map<String, String>>[].obs;
  var products = <Map<String, String>>[].obs;
  var assignees = <Map<String, String>>[].obs;
  var selectedWorkOrder = ''.obs;
  var selectedProduct = ''.obs;
  var selectedAssignee = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWorkOrders();
    fetchProducts();
    fetchAppUsers();
  }

  /// 🔹 Fetch work orders from API
  Future<void> fetchWorkOrders() async {
    try {
      final response = await ApiService.getWorkOrders();
      if (response['success'] == true && response['data'] != null) {
        workOrders.value = (response['data'] as List)
            .map(
              (item) => {
                "id": item["id"].toString(),
                "title": item["title"]?.toString() ?? "Unnamed Work Order",
                "code": item["work_order_code"]?.toString() ?? "",
              },
            )
            .toList();
      }
    } catch (e) {
      print("Error loading work orders: $e");
    }
  }

  /// 🔹 Fetch products from API
  Future<void> fetchProducts() async {
    try {
      final response = await ApiService.getProducts();
      if (response['success'] == true && response['data'] != null) {
        products.value = (response['data'] as List)
            .map(
              (item) => {
                "id": item["id"].toString(),
                "name": item["name"]?.toString() ?? "Unnamed Product",
              },
            )
            .toList();
      }
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  /// 🔹 Fetch app users for assignees
  Future<void> fetchAppUsers() async {
    try {
      final response = await ApiService.getAppUsers();
      if (response['success'] == true && response['data'] != null) {
        assignees.value = (response['data'] as List)
            .map(
              (item) => {
                "id": item["id"].toString(),
                "name": "${item["first_name"]} ${item["last_name"]}",
              },
            )
            .toList();
      }
    } catch (e) {
      print("Error loading app users: $e");
    }
  }

  // 🔹 Add Size Variant with Name, Size, and Quantity
  void addSize() {
    final name = sizeNameController.text.trim();
    final size = sizeController.text.trim();
    final quantityText = sizeQuantityController.text.trim();

    if (name.isEmpty || size.isEmpty || quantityText.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all size variant fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF9800),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        "Invalid Quantity",
        "Please enter a valid quantity number",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    sizeList.add({"name": name, "size": size, "quantity": quantity});

    // Clear all fields
    sizeNameController.clear();
    sizeController.clear();
    sizeQuantityController.clear();
  }

  // 🔹 Remove Size Variant
  void removeSize(Map<String, dynamic> size) {
    sizeList.remove(size);
  }

  // 🔹 Create Batch API Call
  Future<void> createBatch(String workOrderId) async {
    final finalWorkOrderId = workOrderId.isNotEmpty
        ? workOrderId
        : selectedWorkOrder.value;

    if (batchCodeController.text.isEmpty ||
        finalWorkOrderId.isEmpty ||
        quantityController.text.isEmpty ||
        sizeList.isEmpty) {
      Get.snackbar(
        "Missing Fields",
        "Please fill all required fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final body = {
      "work_order_id": finalWorkOrderId,
      "batch_code": batchCodeController.text,
      "planned_quantity": int.tryParse(quantityController.text) ?? 0,
      "size_variants": sizeList
          .map(
            (size) => {
              "name": size["name"],
              "size": size["size"],
              "quantity": size["quantity"],
            },
          )
          .toList(),
      "piece_groups": [],
      "assigned_to": selectedAssignee.value.isNotEmpty
          ? selectedAssignee.value
          : null,
      "notes": notesController.text,
    };

    try {
      final response = await ApiService.createBatch(body);

      isLoading.value = false;

      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "Batch created successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        print("✅ Batch Created Response: ${jsonEncode(response['data'])}");

        // 🔹 Navigate to batch detail view
        final batchId = response['data']['id']?.toString();
        if (batchId != null && batchId.isNotEmpty && batchId != '0') {
          Get.offNamed('/batch-detail', parameters: {'batchId': batchId});
        } else {
          // Fallback to work order view if batch ID not available
          final workOrderIdStr = finalWorkOrderId.toString();
          if (workOrderIdStr.isNotEmpty && workOrderIdStr != '0') {
            Get.off(() => WorkOrderView(workOrderId: workOrderIdStr));
          } else {
            Get.snackbar(
              "Error",
              "Cannot navigate: Invalid work order ID",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
            );
          }
        }
      } else {
        Get.snackbar(
          "Error",
          "Failed to create batch",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      print("❌ Error creating batch: $e");
    }
  }

  @override
  void onClose() {
    batchCodeController.dispose();
    quantityController.dispose();
    sizeNameController.dispose();
    sizeController.dispose();
    sizeQuantityController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
