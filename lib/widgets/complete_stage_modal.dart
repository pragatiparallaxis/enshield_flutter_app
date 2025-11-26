import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/workorder/work_order_viewmodel.dart';
import 'package:enshield_app/models/work_order_model.dart' hide Worker;
import 'package:enshield_app/models/work_order_model.dart' as models show Worker;
import 'package:enshield_app/services/api_service.dart';

class CompleteStageModal extends StatefulWidget {
  final String workOrderId;
  final WorkOrderItem workOrderItem;
  final String stageName;
  final int stageOrder;
  final VoidCallback onSuccess;
  final WorkOrderStage? existingStageData;

  const CompleteStageModal({
    super.key,
    required this.workOrderId,
    required this.workOrderItem,
    required this.stageName,
    required this.stageOrder,
    required this.onSuccess,
    this.existingStageData,
  });

  @override
  State<CompleteStageModal> createState() => _CompleteStageModalState();
}

class _CompleteStageModalState extends State<CompleteStageModal> {
  final _formKey = GlobalKey<FormState>();
  final _inputQuantityController = TextEditingController();
  final _outputQuantityController = TextEditingController();
  final _rejectedQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<Map<String, dynamic>> _workerAssignments = [];
  final Map<int, TextEditingController> _workerQuantityControllers = {};
  List<models.Worker> _workers = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  final List<String> _stages = [
    'cutting',
    'sorting',
    'stitching',
    'finishing',
    'ironing',
    'packing'
  ];

  @override
  void initState() {
    super.initState();
    _rejectedQuantityController.text = '0';
    _loadWorkers();
    _loadInputQuantity();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingStageData != null) {
      final stage = widget.existingStageData!;
      _inputQuantityController.text = stage.input_quantity.toString();
      _outputQuantityController.text = stage.output_quantity.toString();
      _rejectedQuantityController.text = stage.rejected_quantity.toString();
      if (stage.notes != null && stage.notes!.isNotEmpty) {
        _notesController.text = stage.notes!;
      }
      
      // Load existing worker assignments
      if (stage.worker_assignments != null && stage.worker_assignments!.isNotEmpty) {
        for (int i = 0; i < stage.worker_assignments!.length; i++) {
          final assignment = stage.worker_assignments![i];
          _workerAssignments.add({
            'workers_id': assignment.workers_id,
            'quantity': assignment.quantity,
          });
          _workerQuantityControllers[i] = TextEditingController(
            text: assignment.quantity.toString(),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _inputQuantityController.dispose();
    _outputQuantityController.dispose();
    _rejectedQuantityController.dispose();
    _notesController.dispose();
    // Dispose all worker quantity controllers
    for (var controller in _workerQuantityControllers.values) {
      controller.dispose();
    }
    _workerQuantityControllers.clear();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getWorkers();
      if (response["success"] == true && response["data"] != null) {
        setState(() {
          _workers = (response["data"] as List)
              .map((item) => models.Worker.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load workers: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadInputQuantity() {
    final itemStages = widget.workOrderItem.work_order_stages ?? [];
    final stageOrder = widget.stageOrder;

    if (stageOrder == 1) {
      // First stage (cutting), use item quantity
      _inputQuantityController.text = widget.workOrderItem.quantity.toString();
    } else {
      // Find the last completed stage before the current stage
      for (int i = stageOrder - 2; i >= 0; i--) {
        final prevStageName = _stages[i];
        try {
          final prevStage = itemStages.firstWhere(
            (s) => s.stage_name == prevStageName && s.status == 'completed',
          );
          
          _inputQuantityController.text = prevStage.output_quantity.toString();
          return;
        } catch (e) {
          // Stage not found, continue to next
          continue;
        }
      }
      
      // If no previous stage is completed, use item quantity
      _inputQuantityController.text = widget.workOrderItem.quantity.toString();
    }
  }

  void _addWorker() {
    setState(() {
      final newIndex = _workerAssignments.length;
      _workerAssignments.add({
        'workers_id': null,
        'quantity': 0,
      });
      // Create and store controller for the new worker assignment
      _workerQuantityControllers[newIndex] = TextEditingController(text: '0');
    });
  }

  void _removeWorker(int index) {
    setState(() {
      // Dispose the controller for the removed worker
      _workerQuantityControllers[index]?.dispose();
      _workerQuantityControllers.remove(index);
      
      // Update indices for remaining controllers
      final updatedControllers = <int, TextEditingController>{};
      for (var entry in _workerQuantityControllers.entries) {
        if (entry.key > index) {
          updatedControllers[entry.key - 1] = entry.value;
        } else if (entry.key < index) {
          updatedControllers[entry.key] = entry.value;
        }
      }
      _workerQuantityControllers.clear();
      _workerQuantityControllers.addAll(updatedControllers);
      
      _workerAssignments.removeAt(index);
    });
  }

  void _updateWorker(int index, String field, dynamic value) {
    setState(() {
      _workerAssignments[index][field] = value;
    });
  }

  int _getTotalAssigned() {
    return _workerAssignments.fold<int>(
      0,
      (sum, wa) => sum + (wa['quantity'] as int? ?? 0),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final inputQty = int.parse(_inputQuantityController.text);
      final outputQty = int.parse(_outputQuantityController.text);
      final rejectedQty = int.parse(_rejectedQuantityController.text);

      if (outputQty + rejectedQty > inputQty) {
        Get.snackbar("Error", "Output + Rejected cannot exceed Input quantity",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return;
      }

      final totalAssigned = _getTotalAssigned();
      if (_workerAssignments.isNotEmpty && totalAssigned > outputQty) {
        Get.snackbar("Error", "Total worker assignments cannot exceed output quantity",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final workerAssignments = _workerAssignments
            .where((wa) => wa['workers_id'] != null)
            .map((wa) => {
              'workers_id': wa['workers_id'],
              'quantity': wa['quantity'],
            })
            .toList();

        final body = {
          'work_order_item_id': widget.workOrderItem.id,
          'stage_name': widget.stageName,
          'stage_order': widget.stageOrder,
          'input_quantity': inputQty,
          'output_quantity': outputQty,
          'rejected_quantity': rejectedQty,
          if (workerAssignments.isNotEmpty) 'worker_assignments': workerAssignments,
          if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
        };

        final response = await ApiService.completeStage(widget.workOrderId, body);
        
        if (response["success"] == true) {
          Get.back();
          widget.onSuccess();
          Get.snackbar("Success", "Stage completed successfully!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade100);
        } else {
          Get.snackbar("Error", response["message"] ?? "Failed to complete stage",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100);
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to complete stage: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text(
                        widget.existingStageData != null
                            ? 'View ${widget.stageName.toUpperCase()} Stage'
                            : 'Complete ${widget.stageName.toUpperCase()} Stage'
                      ),
                      backgroundColor: const Color(0xFF1E1E2E),
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close),
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
                            // Input Quantity
                            TextFormField(
                              controller: _inputQuantityController,
                              decoration: _fieldDecoration("Input Quantity *"),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter input quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Output Quantity
                            TextFormField(
                              controller: _outputQuantityController,
                              decoration: _fieldDecoration("Output Quantity *"),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              readOnly: widget.existingStageData != null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter output quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                final outputQty = int.parse(value);
                                final inputQty = int.tryParse(_inputQuantityController.text) ?? 0;
                                final rejectedQty = int.tryParse(_rejectedQuantityController.text) ?? 0;
                                if (outputQty + rejectedQty > inputQty) {
                                  return 'Output + Rejected cannot exceed Input';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Rejected Quantity
                            TextFormField(
                              controller: _rejectedQuantityController,
                              decoration: _fieldDecoration("Rejected Quantity *"),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              readOnly: widget.existingStageData != null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter rejected quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Worker Assignments
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Worker Assignments (Optional)",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.existingStageData == null)
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Color(0xFFFF6F00)),
                                    onPressed: _addWorker,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Worker Assignment List
                            if (_workerAssignments.isNotEmpty)
                              ..._workerAssignments.asMap().entries.map((entry) {
                                final index = entry.key;
                                final assignment = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F111A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          decoration: _fieldDecoration("Worker"),
                                          value: assignment['workers_id'] != null ? assignment['workers_id'].toString() : null,
                                          dropdownColor: const Color(0xFF0F111A),
                                          style: const TextStyle(color: Colors.white),
                                          iconEnabledColor: Colors.white,
                                          iconDisabledColor: Colors.grey,
                                          isExpanded: true,
                                          items: _workers.map<DropdownMenuItem<String>>((worker) {
                                            return DropdownMenuItem<String>(
                                              value: worker.id,
                                              child: Text(
                                                worker.name,
                                                style: const TextStyle(color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: widget.existingStageData != null ? null : (value) {
                                            _updateWorker(index, 'workers_id', value);
                                          },
                                          selectedItemBuilder: (BuildContext context) {
                                            return _workers.map((worker) {
                                              return Text(
                                                worker.name,
                                                style: const TextStyle(color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller: _workerQuantityControllers[index] ??= TextEditingController(text: assignment['quantity']?.toString() ?? '0'),
                                          decoration: _fieldDecoration("Qty"),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: Colors.white),
                                          readOnly: widget.existingStageData != null,
                                          onChanged: widget.existingStageData != null ? null : (value) {
                                            final qty = int.tryParse(value) ?? 0;
                                            _updateWorker(index, 'quantity', qty);
                                          },
                                        ),
                                      ),
                                      if (widget.existingStageData == null)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeWorker(index),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            
                            const SizedBox(height: 16),
                            
                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: _fieldDecoration("Notes (Optional)"),
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              readOnly: widget.existingStageData != null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: widget.existingStageData != null
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6F00),
                                ),
                                child: const Text("Close", style: TextStyle(color: Colors.white)),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
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
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text("Complete", style: TextStyle(color: Colors.white)),
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

  InputDecoration _fieldDecoration(String label) {
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
