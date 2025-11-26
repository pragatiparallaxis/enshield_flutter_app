import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/viewmodels/worker/worker_list_viewmodel.dart';

class WorkerEditViewModel extends GetxController {
  final String workerId;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  var isActive = true.obs;
  var isOutsourced = false.obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  WorkerEditViewModel(this.workerId);

  @override
  void onInit() {
    super.onInit();
    loadWorker();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  /// Load worker data
  Future<void> loadWorker() async {
    try {
      isLoading.value = true;
      final response = await ApiService.getWorker(workerId);
      print("📦 Worker Response: $response");

      if (response["success"] == true && response["data"] != null) {
        final worker = response["data"];
        nameController.text = worker["name"] ?? '';
        emailController.text = worker["email"] ?? '';
        phoneController.text = worker["phone"] ?? '';
        isActive.value = worker["is_active"] ?? true;
        isOutsourced.value = worker["is_outsourced"] ?? false;
      } else {
        Get.snackbar("Error", "Failed to load worker",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        Get.back();
      }
    } catch (e) {
      print("❌ Error loading worker: $e");
      Get.snackbar("Error", "Failed to load worker",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update worker
  Future<void> updateWorker() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Name is required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    try {
      isSubmitting.value = true;

      final body = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        "phone": phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        "is_active": isActive.value,
        "is_outsourced": isOutsourced.value,
      };

      print("📤 Updating Worker: $body");

      final response = await ApiService.updateWorker(workerId, body);
      print("✅ Worker API Response: $response");

      if (response["success"] == true && response["data"] != null) {
        // Navigate back first
        Get.back();
        
        // Refresh worker list if it exists
        if (Get.isRegistered<WorkerListViewModel>()) {
          Get.find<WorkerListViewModel>().refresh();
        }
        
        // Show success message on previous page
        Get.snackbar("Success", "Worker updated successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
      } else {
        Get.snackbar(
            "Error", response["error"] ?? "Failed to update worker",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      print("❌ Error updating worker: $e");
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isSubmitting.value = false;
    }
  }

  void cancel() {
    Get.back();
  }
}

