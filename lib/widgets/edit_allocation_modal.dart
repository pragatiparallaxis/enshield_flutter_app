import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/viewmodels/workorder/work_order_viewmodel.dart';

class EditAllocationModal extends StatefulWidget {
  final String workOrderId;
  final WorkOrderInventory inventory;
  final VoidCallback onSuccess;

  const EditAllocationModal({
    super.key,
    required this.workOrderId,
    required this.inventory,
    required this.onSuccess,
  });

  @override
  State<EditAllocationModal> createState() => _EditAllocationModalState();
}

class _EditAllocationModalState extends State<EditAllocationModal> {
  final _formKey = GlobalKey<FormState>();
  final _layersController = TextEditingController();
  final _pairsPerLayerController = TextEditingController();
  final _ratioController = TextEditingController();
  
  // State for dynamic fields
  String? _selectedCategoryId;
  String? _selectedSizeId;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _layersController.text = (widget.inventory.layers_used ?? 0).toString();
    _pairsPerLayerController.text = (widget.inventory.pairs_per_layer ?? 0).toString();
    _ratioController.text = (widget.inventory.ratio_per_piece ?? 0).toString();
    
    // Initialize dropdowns if data exists
    if (widget.inventory.categories != null && widget.inventory.categories!.isNotEmpty) {
      _selectedCategoryId = widget.inventory.categories!.first.id;
    }
    
    if (widget.inventory.sizes != null && widget.inventory.sizes!.isNotEmpty) {
      _selectedSizeId = widget.inventory.sizes!.first.id;
    }
  }

  @override
  void dispose() {
    _layersController.dispose();
    _pairsPerLayerController.dispose();
    _ratioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = Get.find<WorkOrderViewModel>();
      
      // Prepare update data
      final updates = <String, dynamic>{
        'layers_used': int.parse(_layersController.text),
        'pairs_per_layer': int.parse(_pairsPerLayerController.text),
        'ratio_per_piece': double.parse(_ratioController.text),
      };

      if (_selectedCategoryId != null) {
        updates['category_id'] = _selectedCategoryId;
      }
      
      if (_selectedSizeId != null) {
        updates['size_id'] = _selectedSizeId;
      }

      final success = await controller.updateInventoryAllocation(
        widget.workOrderId,
        widget.inventory.id.toString(),
        updates,
      );

      if (success) {
        Get.back();
        widget.onSuccess();
        Get.snackbar(
          "Success",
          "Allocation updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update allocation: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Edit Allocation', style: TextStyle(color: Colors.white)),
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
                      // Info Card
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
                              'Current Inventory Info',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Color', widget.inventory.color ?? 'N/A'),
                            if (widget.inventory.fabric != null)
                              _buildInfoRow('Fabric', widget.inventory.fabric!),
                            _buildInfoRow('Total Meters', '${widget.inventory.total_meters}m'),
                            _buildInfoRow('Table Length', '${widget.inventory.table_length}m'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Editable Fields
                      TextFormField(
                        controller: _layersController,
                        decoration: _inputDecoration('Layers Used *'),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _pairsPerLayerController,
                        decoration: _inputDecoration('Pairs per Layer *'),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _ratioController,
                        decoration: _inputDecoration('Ratio per Piece *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      if (widget.inventory.categories != null && 
                          widget.inventory.categories!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Category'),
                          value: _selectedCategoryId,
                          dropdownColor: const Color(0xFF0F111A),
                          style: const TextStyle(color: Colors.white),
                          items: widget.inventory.categories!.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                        ),
                      
                      const SizedBox(height: 16),

                      // Size Dropdown
                      if (widget.inventory.sizes != null && 
                          widget.inventory.sizes!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Size'),
                          value: _selectedSizeId,
                          dropdownColor: const Color(0xFF0F111A),
                          style: const TextStyle(color: Colors.white),
                          items: widget.inventory.sizes!.map((size) {
                            return DropdownMenuItem<String>(
                              value: size.id,
                              child: Text(size.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSizeId = value);
                          },
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
                        onPressed: _isSubmitting ? null : () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F00),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update', style: TextStyle(color: Colors.white)),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
