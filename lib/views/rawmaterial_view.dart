import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/rawmaterial/raw_material_viewmodel.dart';
import 'package:enshield_app/models/raw_material_model.dart';

class RawMaterialView extends StatelessWidget {
  const RawMaterialView({super.key});

  @override
  Widget build(BuildContext context) {
    final RawMaterialViewModel controller = Get.put(RawMaterialViewModel());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Material Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMaterialDialog(context, controller);
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Summary cards
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard(
                        'Total Items', controller.totalItems.value.toString()),
                    _buildSummaryCard(
                        'Low Stock', controller.lowStockCount.value.toString()),
                    _buildSummaryCard(
                        'Used Today', '${controller.usedToday.value} m'),
                  ],
                )),
            const SizedBox(height: 10),
            // Material list
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: controller.materials.length,
                    itemBuilder: (context, index) {
                      final item = controller.materials[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text(item.name),
                          subtitle: Text(
                              'Category: ${item.category} • ${item.quantity} ${item.unit}'),
                          trailing: Chip(
                            label: Text(item.status),
                            backgroundColor: item.status == 'Low Stock'
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                          ),
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddMaterialDialog(
      BuildContext context, RawMaterialViewModel controller) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Add New Material",
      content: Column(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Material Name')),
          TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
          TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
        ],
      ),
      textConfirm: "Add",
      onConfirm: () {
        if (nameCtrl.text.isNotEmpty &&
            categoryCtrl.text.isNotEmpty &&
            qtyCtrl.text.isNotEmpty &&
            unitCtrl.text.isNotEmpty) {
          controller.addMaterial(RawMaterialModel(
            name: nameCtrl.text,
            category: categoryCtrl.text,
            quantity: double.tryParse(qtyCtrl.text) ?? 0,
            unit: unitCtrl.text,
            status: 'In Stock',
          ));
          Get.back();
        }
      },
      textCancel: "Cancel",
    );
  }
}
