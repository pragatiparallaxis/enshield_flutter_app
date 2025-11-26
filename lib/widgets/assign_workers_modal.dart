import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/models/work_order_model.dart' as models;
import 'package:enshield_app/services/api_service.dart';

class AssignWorkersModal extends StatefulWidget {
  final String workOrderId;
  final String stageId;
  final String workOrderItemId;
  final String stageName;
  final int inputQuantity;
  final int? stageOrder;
  final VoidCallback onSuccess;

  const AssignWorkersModal({
    super.key,
    required this.workOrderId,
    required this.stageId,
    required this.workOrderItemId,
    required this.stageName,
    required this.inputQuantity,
    this.stageOrder,
    required this.onSuccess,
  });

  @override
  State<AssignWorkersModal> createState() => _AssignWorkersModalState();
}

class _AssignWorkersModalState extends State<AssignWorkersModal> {
  final _formKey = GlobalKey<FormState>();
  List<models.Worker> _workers = [];
  List<models.WorkerAssignment> _assignments = [];
  List<models.InventoryItem> _inventoryItems = [];
  // Map to track inventory items for each assignment index
  Map<int, List<Map<String, dynamic>>> _assignmentInventory = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _remainingQuantity = 0;

  @override
  void initState() {
    super.initState();
    _remainingQuantity = widget.inputQuantity;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load workers
      final workersResponse = await ApiService.getWorkers();
      if (workersResponse["success"] == true && workersResponse["data"] != null) {
        _workers = (workersResponse["data"] as List)
            .where((w) => w['is_active'] == true)
            .map((item) => models.Worker.fromJson(item))
            .toList();
      }

      // Load inventory items
      final inventoryResponse = await ApiService.getInventoryItemsForManagement();
      if (inventoryResponse["success"] == true && inventoryResponse["data"] != null) {
        _inventoryItems = (inventoryResponse["data"] as List)
            .where((item) => (item['available'] ?? 0) > 0) // Only show items with available quantity
            .map((item) => models.InventoryItem.fromJson(item))
            .toList();
      }

      // Load existing assignments
      final assignmentsResponse = await ApiService.getStageWorkerAssignments(
        widget.workOrderId,
        widget.stageId,
      );
      if (assignmentsResponse["success"] == true && assignmentsResponse["data"] != null) {
        _assignments = (assignmentsResponse["data"] as List)
            .map((item) => models.WorkerAssignment.fromJson(item))
            .toList();
        _updateRemainingQuantity();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateRemainingQuantity() {
    final assignedTotal = _assignments.fold<int>(
      0,
      (sum, assignment) => sum + (assignment.quantity),
    );
    setState(() {
      _remainingQuantity = widget.inputQuantity - assignedTotal;
    });
  }

  void _addAssignment() {
    if (_workers.isEmpty) {
      Get.snackbar("Error", "No workers available",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() {
      final newIndex = _assignments.length;
      // Use 0 for temporary ID, and parse stageId to int if possible, else 0
      final stageIdInt = int.tryParse(widget.stageId) ?? 0;
      
      _assignments.add(models.WorkerAssignment(
        id: 0,
        work_order_stages_id: stageIdInt,
        workers_id: _workers.first.id,
        quantity: 0,
        status: 'assigned',
        worker_output_quantity: 0,
        admin_approved_quantity: 0,
      ));
      _assignmentInventory[newIndex] = [];
    });
  }

  void _removeAssignment(int index) {
    setState(() {
      _assignments.removeAt(index);
      _assignmentInventory.remove(index);
      // Rebuild inventory map indices
      final newMap = <int, List<Map<String, dynamic>>>{};
      _assignmentInventory.forEach((key, value) {
        if (key > index) {
          newMap[key - 1] = value;
        } else if (key < index) {
          newMap[key] = value;
        }
      });
      _assignmentInventory = newMap;
      _updateRemainingQuantity();
    });
  }

  // Get valid worker dropdown value
  String? _getValidWorkerValue(dynamic workersId, List<models.Worker> availableWorkers) {
    if (workersId == null) return null;
    final workersIdStr = workersId.toString();
    final items = _getUniqueWorkerDropdownItems(availableWorkers);
    if (items.any((item) => item.value == workersIdStr)) {
      return workersIdStr;
    }
    return null;
  }

  // Get unique worker dropdown items (handle duplicate IDs)
  List<DropdownMenuItem<String>> _getUniqueWorkerDropdownItems(List<models.Worker> workers) {
    final items = <DropdownMenuItem<String>>[];
    final seenIds = <String>{};
    
    for (final worker in workers) {
      final idStr = worker.id; // ID is already a string (UUID)
      if (!seenIds.contains(idStr)) {
        seenIds.add(idStr);
        items.add(
          DropdownMenuItem<String>(
            value: idStr,
            child: Text(
              worker.name,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    
    return items;
  }

  void _updateAssignmentWorker(int index, String? workerId) {
    if (workerId == null || workerId.isEmpty) return;
    setState(() {
      // Create new instance since WorkerAssignment is immutable
      final old = _assignments[index];
      _assignments[index] = models.WorkerAssignment(
        id: old.id,
        work_order_stages_id: old.work_order_stages_id,
        workers_id: workerId,
        quantity: old.quantity,
        status: old.status,
        worker_output_quantity: old.worker_output_quantity,
        admin_approved_quantity: old.admin_approved_quantity,
        worker: old.worker,
        worker_notes: old.worker_notes,
        admin_notes: old.admin_notes,
      );
      _updateRemainingQuantity();
    });
  }

  void _updateAssignmentQuantity(int index, int quantity) {
    setState(() {
      // Create new instance since WorkerAssignment is immutable
      final old = _assignments[index];
      _assignments[index] = models.WorkerAssignment(
        id: old.id,
        work_order_stages_id: old.work_order_stages_id,
        workers_id: old.workers_id,
        quantity: quantity,
        status: old.status,
        worker_output_quantity: old.worker_output_quantity,
        admin_approved_quantity: old.admin_approved_quantity,
        worker: old.worker,
        worker_notes: old.worker_notes,
        admin_notes: old.admin_notes,
      );
      _updateRemainingQuantity();
    });
  }

  void _addInventoryItem(int assignmentIndex) {
    setState(() {
      if (!_assignmentInventory.containsKey(assignmentIndex)) {
        _assignmentInventory[assignmentIndex] = [];
      }
      _assignmentInventory[assignmentIndex]!.add({
        'inventory_id': _inventoryItems.isNotEmpty ? _inventoryItems.first.id : '',
        'quantity_provided': 0,
      });
    });
  }

  void _removeInventoryItem(int assignmentIndex, int itemIndex) {
    setState(() {
      _assignmentInventory[assignmentIndex]?.removeAt(itemIndex);
    });
  }

  void _updateInventoryItem(int assignmentIndex, int itemIndex, String? inventoryId, int quantity) {
    setState(() {
      if (_assignmentInventory[assignmentIndex] != null && 
          itemIndex < _assignmentInventory[assignmentIndex]!.length) {
        if (inventoryId != null) {
          _assignmentInventory[assignmentIndex]![itemIndex]['inventory_id'] = inventoryId;
        }
        _assignmentInventory[assignmentIndex]![itemIndex]['quantity_provided'] = quantity;
      }
    });
  }

  Future<void> _submitAssignments() async {
    if (_assignments.isEmpty) {
      Get.snackbar("Error", "Please add at least one worker assignment",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    if (_remainingQuantity < 0) {
      Get.snackbar("Error", "Total assigned quantity exceeds input quantity",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    if (_assignments.any((a) => a.quantity <= 0)) {
      Get.snackbar("Error", "All assignments must have quantity > 0",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final assignmentsData = _assignments.map((a) {
        return {
          'worker_id': a.workers_id,
          'quantity': a.quantity,
        };
      }).toList();

      final requestBody = <String, dynamic>{
        'work_order_item_id': widget.workOrderItemId,
        'assignments': assignmentsData,
      };

      // If stageId is "new", include stage creation info
      if (widget.stageId == 'new' && widget.stageOrder != null) {
        requestBody['stage_name'] = widget.stageName;
        requestBody['input_quantity'] = widget.inputQuantity;
        requestBody['stage_order'] = widget.stageOrder!;
      }

      // Assign workers first
      final response = await ApiService.assignWorkersToStage(
        widget.workOrderId,
        widget.stageId,
        requestBody,
      );

      if (response["success"] == true) {
        // Get the created assignment IDs from the response
        final assignments = response["data"] as List?;
        if (assignments != null && assignments.isNotEmpty) {
          // Get the final stage ID (might be newly created)
          String finalStageId = widget.stageId;
          if (widget.stageId == 'new' && assignments.isNotEmpty) {
            final firstAssignment = assignments[0] as Map<String, dynamic>;
            finalStageId = firstAssignment['work_order_stages_id']?.toString() ?? widget.stageId;
          }

          // Allocate inventory to workers if any inventory items were selected
          bool hasInventory = _assignmentInventory.values.any((items) => 
            items.any((item) => item['inventory_id'] != null && 
                                item['inventory_id'].toString().isNotEmpty && 
                                (item['quantity_provided'] ?? 0) > 0));

          if (hasInventory) {
            final allocations = <Map<String, dynamic>>[];
            
            for (int i = 0; i < assignments.length && i < _assignments.length; i++) {
              final assignment = assignments[i] as Map<String, dynamic>;
              final assignmentId = assignment['id']?.toString() ?? assignment['assignment_id']?.toString();
              
              if (assignmentId != null && _assignmentInventory.containsKey(i)) {
                final inventoryItems = _assignmentInventory[i]!
                    .where((item) => item['inventory_id'] != null && 
                                    item['inventory_id'].toString().isNotEmpty && 
                                    (item['quantity_provided'] ?? 0) > 0)
                    .map<Map<String, dynamic>>((item) => {
                      'inventory_id': item['inventory_id'].toString(),
                      'quantity_provided': item['quantity_provided'],
                    } as Map<String, dynamic>).toList();

                if (inventoryItems.isNotEmpty) {
                  // Convert assignmentId to number (backend expects number)
                  final assignmentIdNum = int.tryParse(assignmentId) ?? 0;
                  if (assignmentIdNum > 0) {
                    allocations.add({
                      'worker_assignment_id': assignmentIdNum,
                      'inventory_items': inventoryItems,
                    });
                  }
                }
              }
            }

            if (allocations.isNotEmpty) {
              try {
                await ApiService.allocateInventoryToWorkers(
                  widget.workOrderId,
                  finalStageId,
                  {'allocations': allocations},
                );
              } catch (e) {
                // Log error but don't fail the whole operation
                print('Warning: Failed to allocate inventory: $e');
                Get.snackbar(
                  "Warning",
                  "Workers assigned but inventory allocation failed: ${e.toString()}",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.black87,
                  duration: const Duration(seconds: 3),
                );
              }
            }
          }

          Get.snackbar(
            "Success",
            "Workers assigned${hasInventory ? ' and inventory allocated' : ''} successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.black87,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            "Success",
            "Workers assigned successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.black87,
            duration: const Duration(seconds: 2),
          );
        }
        
        widget.onSuccess();
        Get.back();
      } else {
        throw Exception(response["error"] ?? "Failed to assign workers");
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to assign workers: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black87,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF0F111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF9800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            AppBar(
              title: Text('Assign Workers - ${widget.stageName.toUpperCase()}'),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Input quantity info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F111A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Input Quantity:",
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    "${widget.inputQuantity}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _remainingQuantity < 0
                                    ? Colors.red.withOpacity(0.2)
                                    : _remainingQuantity == 0
                                        ? Colors.green.withOpacity(0.2)
                                        : const Color(0xFF0F111A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _remainingQuantity < 0
                                      ? Colors.red
                                      : _remainingQuantity == 0
                                          ? Colors.green
                                          : Colors.white24,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Remaining:",
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    "$_remainingQuantity",
                                    style: TextStyle(
                                      color: _remainingQuantity < 0
                                          ? Colors.red
                                          : _remainingQuantity == 0
                                              ? Colors.green
                                              : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Assignments list
                            ...List.generate(_assignments.length, (index) {
                              final assignment = _assignments[index];
                              final availableWorkers = _workers
                                  .where((w) =>
                                      w.id.toString() == assignment.workers_id?.toString() ||
                                      !_assignments.any((a) =>
                                          a.workers_id?.toString() == w.id.toString() && a != assignment))
                                  .toList();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F111A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            decoration: _fieldDecoration("Worker *"),
                                            value: _getValidWorkerValue(assignment.workers_id, availableWorkers),
                                            dropdownColor: const Color(0xFF0F111A),
                                            style: const TextStyle(color: Colors.white),
                                            isExpanded: true,
                                            items: _getUniqueWorkerDropdownItems(availableWorkers),
                                            onChanged: (value) =>
                                                _updateAssignmentWorker(index, value),
                                            selectedItemBuilder: (BuildContext context) {
                                              return availableWorkers.map<Widget>((worker) {
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
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeAssignment(index),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      decoration: _fieldDecoration("Quantity *"),
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      initialValue: assignment.quantity.toString(),
                                      onChanged: (value) {
                                        final qty = int.tryParse(value) ?? 0;
                                        _updateAssignmentQuantity(index, qty);
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter quantity';
                                        }
                                        final qty = int.tryParse(value);
                                        if (qty == null || qty <= 0) {
                                          return 'Quantity must be > 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    // Inventory allocation section
                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.white24),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text(
                                          "Inventory Items",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, 
                                            color: Color(0xFFFF9800), size: 20),
                                          onPressed: () => _addInventoryItem(index),
                                          tooltip: "Add inventory item",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Display inventory items for this assignment
                                    if (_assignmentInventory.containsKey(index) && 
                                        _assignmentInventory[index]!.isNotEmpty)
                                      ...(_assignmentInventory[index]!.asMap().entries.map((entry) {
                                        final itemIndex = entry.key;
                                        final item = entry.value;
                                        final inventoryId = item['inventory_id']?.toString() ?? '';
                                        final selectedInventory = _inventoryItems.firstWhere(
                                          (inv) => inv.id == inventoryId,
                                          orElse: () => _inventoryItems.isNotEmpty 
                                              ? _inventoryItems.first 
                                              : models.InventoryItem(
                                                  id: '',
                                                  name: 'No items available',
                                                  total: 0,
                                                  available: 0,
                                                  taken_quantity: 0,
                                                ),
                                        );
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A0B12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: DropdownButtonFormField<String>(
                                                  value: inventoryId.isNotEmpty && 
                                                      _inventoryItems.any((inv) => inv.id == inventoryId)
                                                      ? inventoryId
                                                      : null,
                                                  decoration: InputDecoration(
                                                    labelText: "Item",
                                                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                                    filled: true,
                                                    fillColor: const Color(0xFF0F111A),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: const BorderSide(color: Colors.white24),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                  dropdownColor: const Color(0xFF0F111A),
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  isExpanded: true,
                                                  items: _inventoryItems.map<DropdownMenuItem<String>>((inv) {
                                                    return DropdownMenuItem<String>(
                                                      value: inv.id,
                                                      child: Text(
                                                        '${inv.name} (${inv.available} ${inv.unit ?? ''} available)',
                                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      _updateInventoryItem(index, itemIndex, value, 
                                                        item['quantity_provided'] ?? 0);
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 1,
                                                child: TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: "Qty",
                                                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                                    filled: true,
                                                    fillColor: const Color(0xFF0F111A),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: const BorderSide(color: Colors.white24),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  initialValue: (item['quantity_provided'] ?? 0).toString(),
                                                  onChanged: (value) {
                                                    final qty = int.tryParse(value) ?? 0;
                                                    _updateInventoryItem(index, itemIndex, null, qty);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, 
                                                  color: Colors.red, size: 20),
                                                onPressed: () => _removeInventoryItem(index, itemIndex),
                                                tooltip: "Remove item",
                                              ),
                                            ],
                                          ),
                                        );
                                      })),
                                    if (!_assignmentInventory.containsKey(index) || 
                                        _assignmentInventory[index]!.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          "No inventory items assigned",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            // Add assignment button
                            ElevatedButton.icon(
                              onPressed: _addAssignment,
                              icon: const Icon(Icons.add),
                              label: const Text("Add Worker"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Submit button
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitAssignments,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                disabledBackgroundColor: Colors.grey,
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
                                  : const Text(
                                      "Assign Workers",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
