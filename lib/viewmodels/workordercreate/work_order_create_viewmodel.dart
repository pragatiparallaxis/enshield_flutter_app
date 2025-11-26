import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:enshield_app/models/work_order_create_model.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/views/work_order_view.dart';

class WorkOrderCreateViewModel extends GetxController {
  var workOrder = WorkOrderData().obs;
  var isLoading = false.obs;

  /// List of products (id & name)
  var products = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  /// 🔹 Fetch product list from API
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final response = await ApiService.getProducts();
      print("📦 Products Response: $response");

      if (response != null && response["data"] != null) {
        final List dataList = response["data"];

        products.value = dataList
            .map((item) => {
                  "id": item["id"].toString(),
                  "name": item["name"]?.toString() ?? "Unnamed Product",
                })
            .toList();

        print("✅ Products Parsed: ${products.length}");
      } else {
        products.clear();
      }
    } catch (e) {
      print("❌ Error fetching products: $e");
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 Update functions
  void updateCode(String val) => workOrder.update((wo) => wo?.code = val);
  void updateTitle(String val) => workOrder.update((wo) => wo?.title = val);
  void updatePlannedQty(String val) =>
      workOrder.update((wo) => wo?.plannedQty = val);
  void updateProduct(String val) =>
      workOrder.update((wo) => wo?.product = val);
  void updateNotes(String val) =>
      workOrder.update((wo) => wo?.notes = val);
  void updateClientName(String val) =>
      workOrder.update((wo) => wo?.clientName = val);

  /// 🔹 Create Work Order API call
  Future<void> createWorkOrder() async {
    if (workOrder.value.code.isEmpty ||
        workOrder.value.title.isEmpty) {
      Get.snackbar("Error", "Please fill all required fields (Work Order Code and Title)",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "work_order_code": workOrder.value.code,
        "title": workOrder.value.title,
        if (workOrder.value.plannedQty.isNotEmpty) "planned_quantity": int.tryParse(workOrder.value.plannedQty) ?? 0,
        if (workOrder.value.clientName.isNotEmpty) "client_name": workOrder.value.clientName,
        if (workOrder.value.product.isNotEmpty) "product_ids": [workOrder.value.product],
        if (workOrder.value.notes.isNotEmpty) "notes": workOrder.value.notes,
      };

      print("📤 Sending Work Order Body: $body");

      final response = await ApiService.createWorkOrder(body);
      print("✅ Work Order API Response: $response");

      if (response["success"] == true && response["data"] != null) {
        final workOrderIdRaw = response["data"]["id"];
        final workOrderId = workOrderIdRaw?.toString() ?? '';
        
        if (workOrderId.isEmpty || workOrderId == '0') {
          Get.snackbar(
            "Error",
            "Failed to get work order ID from response",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
          );
          return;
        }
        
        print("🆔 Created Work Order ID: $workOrderId");

        Get.snackbar("Success", "Work order created successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);

        /// ✅ Navigate and pass ID to WorkOrderView
        Get.offAll(() => WorkOrderView(workOrderId: workOrderId));
      } else {
        Get.snackbar(
            "Error", response["message"] ?? "Failed to create work order",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  void cancel() {
    Get.back();
  }
}
