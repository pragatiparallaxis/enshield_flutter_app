import 'package:get/get.dart';
import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/services/api_service.dart';

class InventoryViewModel extends GetxController {
  var inventoryItems = <InventoryItem>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadInventoryItems();
  }

  Future<void> loadInventoryItems() async {
    try {
      isLoading.value = true;
      final response = await ApiService.getInventoryItemsForManagement();
      
      if (response["success"] == true && response["data"] != null) {
        var inventoryData = response["data"] as List;
        inventoryItems.value = inventoryData
            .map((item) => InventoryItem.fromJson(item))
            .toList();
      } else {
        Get.snackbar("Error", response["error"] ?? "Failed to load inventory items",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load inventory: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addInventoryInward({
    String? inventoryId,
    String? name,
    String? fabric,
    String? color,
    String? unit,
    required int quantity,
    String? supplier,
    String? purchaseOrder,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      
      final body = <String, dynamic>{
        'quantity': quantity,
      };
      
      if (inventoryId != null) {
        body['inventory_id'] = inventoryId;
      } else if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }
      
      if (fabric != null && fabric.isNotEmpty) body['fabric'] = fabric;
      if (color != null && color.isNotEmpty) body['color'] = color;
      if (unit != null && unit.isNotEmpty) body['unit'] = unit;
      if (supplier != null && supplier.isNotEmpty) body['supplier'] = supplier;
      if (purchaseOrder != null && purchaseOrder.isNotEmpty) body['purchase_order'] = purchaseOrder;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

      final response = await ApiService.addInventoryInward(body);
      
      if (response["success"] == true) {
        await loadInventoryItems();
        Get.snackbar("Success", "Inventory added successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary);
        return true;
      } else {
        Get.snackbar("Error", response["error"] ?? "Failed to add inventory",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to add inventory: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadInventoryItems();
  }
}

