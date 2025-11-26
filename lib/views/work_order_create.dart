import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/workordercreate/work_order_create_viewmodel.dart';

class CreateWorkOrderView extends StatelessWidget {
  final WorkOrderCreateViewModel controller = Get.put(
    WorkOrderCreateViewModel(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text("New Work Order"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C27),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Work Order Details",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter the details for the new work order",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              _textField("Work Order Code *", controller.updateCode),
              const SizedBox(height: 15),

              _textField("Title *", controller.updateTitle),
              const SizedBox(height: 15),

              _textField(
                "Planned Quantity (Optional)",
                controller.updatePlannedQty,
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _textField(
                "Client Name (Optional)",
                controller.updateClientName,
              ),
              const SizedBox(height: 15),

              // 🔽 Dropdown for Products
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.products.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Products Available",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: controller.workOrder.value.product.isEmpty
                      ? null
                      : controller.workOrder.value.product,
                  decoration: _fieldDecoration("Products (Optional)"),
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        "None (Optional)",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ...controller.products
                        .map(
                          (product) => DropdownMenuItem<String>(
                            value: product["id"],
                            child: Text(
                              product["name"] ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    controller.updateProduct(value ?? '');
                  },
                );
              }),
              const SizedBox(height: 15),

              _textField(
                "Notes (Optional)",
                controller.updateNotes,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: controller.cancel,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: controller.createWorkOrder,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "Create Work Order",
                      style: TextStyle(color: Colors.white),
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

  Widget _textField(
    String label,
    Function(String) onChanged, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      onChanged: onChanged,
      decoration: _fieldDecoration(label),
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF0F111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF9800)),
      ),
    );
  }
}
