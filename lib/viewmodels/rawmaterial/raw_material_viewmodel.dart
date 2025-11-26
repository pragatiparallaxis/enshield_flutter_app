import 'package:get/get.dart';
import 'package:enshield_app/models/raw_material_model.dart';

class RawMaterialViewModel extends GetxController {
  // Observable list of materials
  var materials = <RawMaterialModel>[].obs;

  // Summary data
  var totalItems = 0.obs;
  var lowStockCount = 0.obs;
  var usedToday = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRawMaterials();
  }

  void fetchRawMaterials() {
    // Mock data for now (can be replaced with API later)
    materials.value = [
      RawMaterialModel(
        name: 'Cotton Fabric',
        category: 'Fabric',
        quantity: 220,
        unit: 'meters',
        status: 'In Stock',
      ),
      RawMaterialModel(
        name: 'Jacket Chain',
        category: 'Chain',
        quantity: 15,
        unit: 'pcs',
        status: 'Low Stock',
      ),
      RawMaterialModel(
        name: 'Reflective Tape',
        category: 'Tape',
        quantity: 50,
        unit: 'meters',
        status: 'In Stock',
      ),
    ];

    totalItems.value = materials.length;
    lowStockCount.value =
        materials.where((m) => m.status == 'Low Stock').length;
    usedToday.value = 120.0; // example usage
  }

  void addMaterial(RawMaterialModel material) {
    materials.add(material);
    updateSummary();
  }

  void updateSummary() {
    totalItems.value = materials.length;
    lowStockCount.value =
        materials.where((m) => m.status == 'Low Stock').length;
  }
}
