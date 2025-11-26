import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/models/outsourced_party_model.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/viewmodels/outsourced_party/outsourced_party_list_viewmodel.dart';

class OutsourcedPartyCreateViewModel extends GetxController {
  // Form controllers
  final nameController = TextEditingController();
  final serviceTypeController = TextEditingController();
  final contactController = TextEditingController();
  final rateController = TextEditingController();
  final notesController = TextEditingController();

  // State
  var isLoading = false.obs;

  @override
  void onClose() {
    // Dispose controllers
    nameController.dispose();
    serviceTypeController.dispose();
    contactController.dispose();
    rateController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Create outsourced party
  Future<void> createOutsourcedParty() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Company name is required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    if (serviceTypeController.text.trim().isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Service type is required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Prepare data
      final data = {
        'name': nameController.text.trim(),
        'service_type': serviceTypeController.text.trim(),
        'contact': contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
        'rate': rateController.text.trim().isNotEmpty ? double.tryParse(rateController.text.trim()) : null,
        'notes': notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        'is_active': true,
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      print("Creating outsourced party with data: $data");

      final response = await ApiService.createOutsourcedParty(data);
      print("Response: $response");
      print("Response type: ${response.runtimeType}");
      print("Response['success']: ${response['success']}");
      print("Response['success'] == true: ${response['success'] == true}");

      // Check if creation was successful
      if (response != null && response['success'] == true) {
        print("Party created successfully, closing...");
        
        // Close the page first
        Get.back();
        
        // Show success message
        Get.snackbar(
          "Success",
          "Outsourced party created successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        
        // Refresh the list page if it exists
        try {
          final listController = Get.find<OutsourcedPartyListViewModel>();
          await listController.loadOutsourcedParties();
        } catch (e) {
          // List page not loaded, that's okay
          print("List controller not found: $e");
        }
      } else {
        print("Creation failed or response invalid");
        Get.snackbar(
          "Error",
          response?['error'] ?? "Failed to create outsourced party",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      print("Error creating outsourced party: $e");
      Get.snackbar(
        "Error",
        "Failed to create outsourced party: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear form
  void clearForm() {
    nameController.clear();
    serviceTypeController.clear();
    contactController.clear();
    rateController.clear();
    notesController.clear();
  }
}
