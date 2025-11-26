import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/viewmodels/worker/worker_list_viewmodel.dart';

class WorkerCreateViewModel extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController(text: 'User@123');
  var type = 'APP_USER'.obs;
  var isActive = true.obs;
  var isOutsourced = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Create worker
  Future<void> createWorker() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Name is required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar("Error", "Email is required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        "type": type.value,
        "password": passwordController.text.trim().isEmpty ? 'User@123' : passwordController.text.trim(),
        "is_active": isActive.value,
        "is_outsourced": isOutsourced.value,
      };

      print("📤 Creating Worker: $body");

      final response = await ApiService.createWorker(body);
      print("✅ Worker API Response: $response");

      if (response["success"] == true && response["data"] != null) {
        // Navigate back first
        Get.back();
        
        // Refresh worker list if it exists
        if (Get.isRegistered<WorkerListViewModel>()) {
          Get.find<WorkerListViewModel>().refresh();
        }
        
        // Show success message on previous page
        Get.snackbar("Success", "Worker created successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);

        // Clear form
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.text = 'User@123';
        type.value = 'APP_USER';
        isActive.value = true;
        isOutsourced.value = false;
      } else {
        Get.snackbar(
            "Error", response["error"] ?? "Failed to create worker",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      print("❌ Error creating worker: $e");
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

