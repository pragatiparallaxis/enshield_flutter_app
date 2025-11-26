import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/workorder/work_order_viewmodel.dart';
import 'package:enshield_app/models/work_order_model.dart';

class ReturnLayersModal extends StatefulWidget {
  final WorkOrderInventory inventory;
  final VoidCallback onSuccess;

  const ReturnLayersModal({
    super.key,
    required this.inventory,
    required this.onSuccess,
  });

  @override
  State<ReturnLayersModal> createState() => _ReturnLayersModalState();
}

class _ReturnLayersModalState extends State<ReturnLayersModal> {
  final _formKey = GlobalKey<FormState>();
  final _layersController = TextEditingController();
  bool _restockInventory = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Calculate max layers that can be returned
    final layersUsed = widget.inventory.layers_used ?? 0;
    final layersReturned = widget.inventory.layers_returned ?? 0;
    final maxReturnable = layersUsed - layersReturned;
    _layersController.text = maxReturnable > 0 ? maxReturnable.toString() : '0';
  }

  @override
  void dispose() {
    _layersController.dispose();
    super.dispose();
  }

  int get _maxReturnableLayers {
    final layersUsed = widget.inventory.layers_used ?? 0;
    final layersReturned = (widget.inventory.layers_returned ?? 0).toInt();
    return layersUsed - layersReturned;
  }

  Future<void> _handleReturn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final layersToReturn = int.parse(_layersController.text);
    
    if (layersToReturn <= 0) {
      Get.snackbar("Error", "Layers to return must be greater than 0",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    if (layersToReturn > _maxReturnableLayers) {
      Get.snackbar("Error", "Cannot return more than $_maxReturnableLayers layers",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = Get.find<WorkOrderViewModel>();
      final success = await controller.returnLayers(
        widget.inventory.id.toString(), // Convert int ID to String for API
        layersToReturn,
        restockInventory: _restockInventory,
      );
      
      if (success) {
        Get.back();
        widget.onSuccess();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to return layers: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layersUsed = widget.inventory.layers_used ?? 0;
    final layersReturned = widget.inventory.layers_returned ?? 0;
    final effectiveLayers = layersUsed - layersReturned;
    final pairsPerLayer = widget.inventory.pairs_per_layer ?? 0;
    final tableLength = widget.inventory.table_length;
    
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
                title: const Text('Return Layers', style: TextStyle(color: Colors.white)),
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
                      // Inventory Info Card
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
                              'Inventory Allocation',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Color', widget.inventory.color ?? ''),
                            if (widget.inventory.fabric != null)
                              _buildInfoRow('Fabric', widget.inventory.fabric!),
                            _buildInfoRow('Total Meters', '${widget.inventory.total_meters}m'),
                            _buildInfoRow('Table Length', '${tableLength}m'),
                            const Divider(color: Colors.white12, height: 24),
                            _buildInfoRow('Layers Used', layersUsed.toString()),
                            _buildInfoRow('Layers Returned', layersReturned.toString()),
                            _buildInfoRow('Effective Layers', effectiveLayers.toString(), 
                                color: Colors.green),
                            if (pairsPerLayer > 0)
                              _buildInfoRow('Pairs per Layer', pairsPerLayer.toString()),
                            _buildInfoRow('Current Output', '${widget.inventory.output_quantity ?? 0} pieces'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Layers to Return
                      TextFormField(
                        controller: _layersController,
                        decoration: _inputDecoration('Layers to Return *'),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of layers';
                          }
                          final layers = int.tryParse(value);
                          if (layers == null || layers <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          if (layers > _maxReturnableLayers) {
                            return 'Cannot return more than $_maxReturnableLayers layers';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maximum returnable: $_maxReturnableLayers layers',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      
                      // Preview of new quantities (update on text change)
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _layersController,
                        builder: (context, value, child) {
                          final layersToReturn = int.tryParse(value.text) ?? 0;
                          if (layersToReturn <= 0 || layersToReturn > _maxReturnableLayers) {
                            return const SizedBox.shrink();
                          }
                          
                          final newEffectiveLayers = effectiveLayers - layersToReturn;
                          final newOutput = pairsPerLayer > 0 
                              ? newEffectiveLayers * pairsPerLayer 
                              : 0;
                          final itemCount = widget.inventory.work_order_items?.length ?? 1;
                          final newQuantityPerItem = itemCount > 0 
                              ? (newOutput / itemCount).floor() 
                              : 0;
                          
                          return Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'After Return:',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow('New Effective Layers', newEffectiveLayers.toString(),
                                    color: Colors.blue),
                                if (pairsPerLayer > 0)
                                  _buildInfoRow('New Total Output', '$newOutput pieces',
                                      color: Colors.blue),
                                if (itemCount > 0)
                                  _buildInfoRow('New Quantity per Item', '$newQuantityPerItem pieces',
                                      color: Colors.blue),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Restock Inventory Checkbox
                      CheckboxListTile(
                        title: const Text(
                          'Restock Inventory',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Return the fabric meters to inventory',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        value: _restockInventory,
                        onChanged: (value) {
                          setState(() {
                            _restockInventory = value ?? true;
                          });
                        },
                        activeColor: const Color(0xFFFF6F00),
                        checkColor: Colors.white,
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
                        onPressed: _isSubmitting ? null : _handleReturn,
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
                            : const Text('Return Layers', style: TextStyle(color: Colors.white)),
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
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
            style: TextStyle(
              color: color ?? Colors.white,
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
