import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/models/outsourced_party_model.dart';
import 'package:enshield_app/services/api_service.dart';

class OutsourcedPartyListViewModel extends GetxController {
  var outsourcedParties = <OutsourcedPartyModel>[].obs;
  var isLoading = false.obs;
  var selectedTabIndex = 0.obs; // 0: All, 1: Active, 2: Inactive

  @override
  void onInit() {
    super.onInit();
    loadOutsourcedParties();
  }

  /// Get filtered parties based on selected tab
  List<OutsourcedPartyModel> get filteredParties {
    switch (selectedTabIndex.value) {
      case 1:
        return outsourcedParties.where((p) => p.isActive == true).toList();
      case 2:
        return outsourcedParties.where((p) => p.isActive == false).toList();
      default:
        return outsourcedParties;
    }
  }

  /// Update selected tab
  void updateSelectedTab(int index) {
    selectedTabIndex.value = index;
  }

  /// Load outsourced parties from API
  Future<void> loadOutsourcedParties() async {
    try {
      isLoading.value = true;

      final response = await ApiService.getOutsourcedParties();

      if (response['success'] == true && response['data'] != null) {
        final partiesData = response['data'] as List;
        final partiesList = partiesData.map((item) {
          return OutsourcedPartyModel.fromJson(item);
        }).toList();

        outsourcedParties.value = partiesList;
        print('Loaded ${partiesList.length} outsourced parties');
      } else {
        Get.snackbar(
          "Error",
          response['error'] ?? "Failed to load outsourced parties",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        outsourcedParties.value = [];
      }
    } catch (e) {
      print("Error loading outsourced parties: $e");
      Get.snackbar(
        "Error",
        "Failed to load outsourced parties: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      outsourcedParties.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Edit outsourced party (quick dialog)
  void editParty(OutsourcedPartyModel party) {
    final nameController = TextEditingController(text: party.name);
    final serviceTypeController = TextEditingController(text: party.serviceType);
    final contactController = TextEditingController(text: party.contact ?? '');
    final rateController = TextEditingController(text: party.rate?.toString() ?? '');
    final notesController = TextEditingController(text: party.notes ?? '');
    final isActive = RxBool(party.isActive);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Edit Party', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameController, 'Name'),
              const SizedBox(height: 8),
              _field(serviceTypeController, 'Service Type'),
              const SizedBox(height: 8),
              _field(contactController, 'Contact'),
              const SizedBox(height: 8),
              _field(rateController, 'Rate per piece', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _field(notesController, 'Notes', maxLines: 3),
              const SizedBox(height: 8),
              Obx(() => CheckboxListTile(
                    value: isActive.value,
                    onChanged: (v) => isActive.value = v ?? true,
                    activeColor: const Color(0xFFFF9800),
                    title: const Text('Active', style: TextStyle(color: Colors.white70)),
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateParty(party.id!, {
                'name': nameController.text.trim(),
                'service_type': serviceTypeController.text.trim(),
                'contact': contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
                'rate': rateController.text.trim().isNotEmpty ? double.tryParse(rateController.text.trim()) : null,
                'notes': notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                'is_active': isActive.value,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF9800)),
        ),
        filled: true,
        fillColor: const Color(0xFF0F111A),
      ),
    );
  }

  Future<void> _updateParty(String id, Map<String, dynamic> data) async {
    try {
      // remove nulls
      data.removeWhere((k, v) => v == null);
      final response = await ApiService.updateOutsourcedParty(id, data);
      if (response['success'] == true) {
        Get.back();
        Get.snackbar('Success', 'Party updated successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
        await loadOutsourcedParties();
      } else {
        Get.snackbar('Error', response['error'] ?? 'Failed to update party', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    }
  }

  /// Toggle party status (activate/deactivate)
  Future<void> togglePartyStatus(OutsourcedPartyModel party) async {
    try {
      final newStatus = !party.isActive;
      
      final response = await ApiService.updateOutsourcedParty(party.id!, {
        'is_active': newStatus,
      });

      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "${party.name} ${newStatus ? 'activated' : 'deactivated'} successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        
        // Refresh the list
        await loadOutsourcedParties();
      } else {
        Get.snackbar(
          "Error",
          response['error'] ?? "Failed to update party status",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      print("Error toggling party status: $e");
      Get.snackbar(
        "Error",
        "Failed to update party status: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  /// Delete outsourced party
  Future<void> deleteParty(OutsourcedPartyModel party) async {
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Delete Party",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete ${party.name}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performDelete(party);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform the actual delete operation
  Future<void> _performDelete(OutsourcedPartyModel party) async {
    try {
      final response = await ApiService.deleteOutsourcedParty(party.id!);

      if (response['success'] == true) {
        Get.snackbar(
          "Success",
          "${party.name} deleted successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        
        // Refresh the list
        await loadOutsourcedParties();
      } else {
        Get.snackbar(
          "Error",
          response['error'] ?? "Failed to delete party",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      print("Error deleting party: $e");
      Get.snackbar(
        "Error",
        "Failed to delete party: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }
}
