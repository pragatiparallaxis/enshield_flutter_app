import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/create_batch/create_batch_viewmodel.dart';

class CreateBatchView extends StatelessWidget {
  final String? workOrderId;
  const CreateBatchView({super.key, this.workOrderId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateBatchViewModel());

    const bgColor = Color(0xFF0F111A);
    const cardColor = Color(0xFF1E1E2E);
    const accentColor = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "New Batch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Create a new production batch",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Batch Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 🏷️ Batch Code + Work Order
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Batch Code *",
                      controller: controller.batchCodeController,
                    ),
                  ),
                  if (workOrderId == null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => _buildDropdown(
                          "Work Order *",
                          controller.workOrders
                              .map((wo) => wo['title'] ?? '')
                              .toList(),
                          controller.selectedWorkOrder,
                          onChanged: (value) {
                            controller.selectedWorkOrder.value = value ?? '';
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // 📦 Planned Quantity
              _buildTextField(
                "Planned Quantity *",
                controller: controller.quantityController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // 📏 Size Variants
              const Text(
                "Size Variants *",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Name",
                      controller: controller.sizeNameController,
                      hint: "e.g., Small, Medium, Large",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      "Size",
                      controller: controller.sizeController,
                      hint: "e.g., S, M, L",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      "Quantity",
                      controller: controller.sizeQuantityController,
                      hint: "e.g., 50",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: controller.addSize,
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text("Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Obx(
                () => Wrap(
                  spacing: 8,
                  children: controller.sizeList
                      .map<Widget>(
                        (size) => Chip(
                          label: Text(
                            "${size['name']} (${size['size']}) - ${size['quantity']}",
                          ),
                          backgroundColor: Color(0xFFFF9800).withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.white70),
                          deleteIcon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 16,
                          ),
                          onDeleted: () => controller.removeSize(size),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 👥 Assigned To
              Obx(
                () => _buildDropdown(
                  "Assigned To (Optional)",
                  controller.assignees
                      .map((user) => user['name'] ?? '')
                      .toList(),
                  controller.selectedAssignee,
                  onChanged: (value) {
                    controller.selectedAssignee.value = value ?? '';
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 📝 Notes
              _buildTextArea(
                "Notes (Optional)",
                controller: controller.notesController,
              ),
              const SizedBox(height: 30),

              // Buttons
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF9800),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                controller.createBatch(workOrderId ?? ''),
                            icon: const Icon(
                              Icons.save_alt,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Create Batch",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6F00),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint ?? "",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F111A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF9800)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    RxString selectedValue, {
    Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F111A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButton<String>(
            value: selectedValue.value.isEmpty ? null : selectedValue.value,
            hint: const Text("Select", style: TextStyle(color: Colors.white38)),
            isExpanded: true,
            dropdownColor: const Color(0xFF0F111A),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF9800)),
            onChanged:
                onChanged ?? ((value) => selectedValue.value = value ?? ''),
            items: items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea(String label, {TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Additional notes...",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F111A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF9800)),
            ),
          ),
        ),
      ],
    );
  }
}
