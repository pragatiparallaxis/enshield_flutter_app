import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/models/work_order_model.dart' hide Worker;
import 'package:enshield_app/models/work_order_model.dart' as models show Worker;

class WorkerListViewModel extends GetxController {
  var workers = <models.Worker>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadWorkers();
  }

  /// Load all workers
  Future<void> loadWorkers() async {
    try {
      isLoading.value = true;
      final response = await ApiService.getWorkers();
      print("📦 Workers Response: $response");

      if (response is Map<String, dynamic> && response["success"] == true && response["data"] != null) {
        final List dataList = response["data"];
        workers.value = dataList
            .map((item) => models.Worker.fromJson(item))
            .toList();
        print("✅ Loaded ${workers.length} workers");
      } else {
        print("⚠️ Workers API returned error: ${response["error"] ?? response["message"]}");
        workers.clear();
        if (response is Map<String, dynamic> && response["error"] != null) {
          Get.snackbar("Error", response["error"] ?? "Failed to load workers",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100);
        }
      }
    } catch (e) {
      print("❌ Error loading workers: $e");
      // Don't show error if it's an authentication error (already handled by API service)
      if (!e.toString().contains('Authentication failed')) {
        Get.snackbar("Error", "Failed to load workers: ${e.toString()}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
      workers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter workers by search query
  List<models.Worker> get filteredWorkers {
    if (searchQuery.value.isEmpty) {
      return workers;
    }
    final query = searchQuery.value.toLowerCase();
    return workers.where((worker) {
      return worker.name.toLowerCase().contains(query) ||
          (worker.email?.toLowerCase().contains(query) ?? false) ||
          (worker.phone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Refresh workers list
  Future<void> refresh() async {
    await loadWorkers();
  }
}

