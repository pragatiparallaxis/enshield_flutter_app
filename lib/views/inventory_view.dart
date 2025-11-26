import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/inventory/inventory_viewmodel.dart';
import 'package:enshield_app/models/work_order_model.dart';

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryViewModel());

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Inventory Management', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInwardDialog(context, controller, null),
        backgroundColor: const Color(0xFFFF6F00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6F00)),
          );
        }

        if (controller.inventoryItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No inventory items',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showInwardDialog(context, controller, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Inventory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.inventoryItems.length,
          itemBuilder: (context, index) {
            final item = controller.inventoryItems[index];
            return _buildInventoryCard(context, item, controller);
          },
        );
      }),
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventoryItem item, InventoryViewModel controller) {
    final available = item.available;
    final isLowStock = available <= 10;
    final isOutOfStock = available == 0;

    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInwardDialog(context, controller, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.fabric != null && item.fabric!.isNotEmpty)
                          Text(
                            'Fabric: ${item.fabric}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        if (item.color != null && item.color!.isNotEmpty)
                          Text(
                            'Color: ${item.color}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        if (item.unit != null && item.unit!.isNotEmpty)
                          Text(
                            'Unit: ${item.unit}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withOpacity(0.2)
                          : isLowStock
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    child: Text(
                      isOutOfStock
                          ? 'Out of Stock'
                          : isLowStock
                              ? 'Low Stock'
                              : 'In Stock',
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuantityInfo('Total', item.total.toString(), Colors.blue),
                  ),
                  Expanded(
                    child: _buildQuantityInfo('Available', available.toString(), Colors.green),
                  ),
                  Expanded(
                    child: _buildQuantityInfo('Taken', item.taken_quantity.toString(), Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showInwardDialog(context, controller, item),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Inventory'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showInwardDialog(BuildContext context, InventoryViewModel controller, InventoryItem? item) {
    final isExisting = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final fabricController = TextEditingController(text: item?.fabric ?? '');
    final colorController = TextEditingController(text: item?.color ?? '');
    final unitController = TextEditingController(text: item?.unit ?? '');
    final quantityController = TextEditingController();
    final supplierController = TextEditingController();
    final purchaseOrderController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E2E),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(
                    isExisting ? 'Add Inventory to Existing Item' : 'Create New Inventory Item',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E1E2E),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isExisting) ...[
                          // Show existing item info (read-only)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F111A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Item: ${item!.name}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                if (item.fabric != null)
                                  Text('Fabric: ${item.fabric}', style: const TextStyle(color: Colors.grey)),
                                if (item.color != null)
                                  Text('Color: ${item.color}', style: const TextStyle(color: Colors.grey)),
                                if (item.unit != null)
                                  Text('Unit: ${item.unit}', style: const TextStyle(color: Colors.grey)),
                                Text(
                                  'Available: ${item.available}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // New item fields
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration('Item Name *'),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter item name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: fabricController,
                                  decoration: _inputDecoration('Fabric'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: colorController,
                                  decoration: _inputDecoration('Color'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: unitController,
                            decoration: _inputDecoration('Unit (e.g., meters, pieces)'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Quantity (always required)
                        TextFormField(
                          controller: quantityController,
                          decoration: _inputDecoration('Quantity to Add *'),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null || int.parse(value) <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: supplierController,
                                decoration: _inputDecoration('Supplier (Optional)'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: purchaseOrderController,
                                decoration: _inputDecoration('Purchase Order (Optional)'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          decoration: _inputDecoration('Notes (Optional)'),
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    final quantity = int.parse(quantityController.text);
                                    final success = await controller.addInventoryInward(
                                      inventoryId: item?.id.toString(),
                                      name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                                      fabric: fabricController.text.trim().isEmpty ? null : fabricController.text.trim(),
                                      color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
                                      unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                                      quantity: quantity,
                                      supplier: supplierController.text.trim().isEmpty ? null : supplierController.text.trim(),
                                      purchaseOrder: purchaseOrderController.text.trim().isEmpty ? null : purchaseOrderController.text.trim(),
                                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                    );
                                    
                                    if (success) {
                                      Get.back();
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F00),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isExisting ? 'Add Inventory' : 'Create & Add',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF0F111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF6F00)),
      ),
    );
  }
}

