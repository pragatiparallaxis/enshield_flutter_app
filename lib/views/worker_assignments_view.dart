import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/worker/worker_assignments_controller.dart';
import 'package:enshield_app/services/api_service.dart';

class WorkerAssignmentsView extends StatelessWidget {
  WorkerAssignmentsView({Key? key}) : super(key: key);

  final WorkerAssignmentsController controller = Get.put(WorkerAssignmentsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text('My Assignments', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.fetchAssignments,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
              }

              if (controller.assignments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No ${controller.selectedFilter.value} assignments found',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.assignments.length,
                itemBuilder: (context, index) {
                  final assignment = controller.assignments[index];
                  return _buildAssignmentCard(context, assignment);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E212B),
      child: Row(
        children: [
          _buildFilterChip('Assigned', 'assigned'),
          const SizedBox(width: 8),
          _buildFilterChip('Submitted', 'submitted'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) controller.setFilter(value);
        },
        backgroundColor: const Color(0xFF2A2D3A),
        selectedColor: const Color(0xFFFF9800),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.black,
      );
    });
  }

  Widget _buildAssignmentCard(BuildContext context, dynamic assignment) {
    final stage = assignment['work_order_stages_id'];
    final workOrder = stage is Map ? stage['work_order_id'] : null;
    
    // Handle nested objects or direct IDs
    final workOrderCode = workOrder is Map ? workOrder['work_order_code'] : 'Unknown Order';
    final workOrderTitle = workOrder is Map ? workOrder['title'] : '';
    final stageName = stage is Map ? stage['stage_name'] : 'Unknown Stage';
    
    // Safely parse quantities
    final quantity = int.tryParse(assignment['quantity']?.toString() ?? '0') ?? 0;
    final outputQty = int.tryParse(assignment['worker_output_quantity']?.toString() ?? '0') ?? 0;
    final approvedQty = int.tryParse(assignment['admin_approved_quantity']?.toString() ?? '0') ?? 0;
    
    final status = assignment['status'] ?? 'assigned';
    final isSubmitted = status == 'submitted' || status == 'approved';

    return Card(
      color: const Color(0xFF1E212B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'approved' 
              ? Colors.green.withOpacity(0.5) 
              : status == 'submitted'
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workOrderCode,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (workOrderTitle.isNotEmpty)
                        Text(
                          workOrderTitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Stage', stageName),
                ),
                Expanded(
                  child: _buildInfoItem('Assigned Qty', '$quantity'),
                ),
              ],
            ),
            if (isSubmitted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Output Qty', '$outputQty', color: Colors.blue),
                  ),
                  if (status == 'approved')
                    Expanded(
                      child: _buildInfoItem('Approved Qty', '$approvedQty', color: Colors.green),
                    ),
                ],
              ),
            ],
            if (!isSubmitted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showSubmitDialog(context, assignment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Submit Work'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'submitted':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showSubmitDialog(BuildContext context, dynamic assignment) {
    showDialog(
      context: context,
      builder: (context) => _SubmitWorkDialog(assignment: assignment, onSuccess: controller.fetchAssignments),
    );
  }
}

class _SubmitWorkDialog extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onSuccess;

  const _SubmitWorkDialog({
    Key? key,
    required this.assignment,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_SubmitWorkDialog> createState() => _SubmitWorkDialogState();
}

class _SubmitWorkDialogState extends State<_SubmitWorkDialog> {
  final outputController = TextEditingController();
  final rejectedController = TextEditingController(text: '0');
  final notesController = TextEditingController();
  bool isSubmitting = false;
  List<Map<String, dynamic>> inventoryAllocations = [];
  Map<String, TextEditingController> returnedControllers = {};
  Map<String, TextEditingController> brokenControllers = {};
  bool isLoadingInventory = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final stage = widget.assignment['work_order_stages_id'];
      final workOrderId = (stage is Map && stage['work_order_id'] is Map) 
          ? stage['work_order_id']['id']?.toString() 
          : null;
      final stageId = stage is Map ? stage['id']?.toString() : null;
      final assignmentId = widget.assignment['id']?.toString();

      if (workOrderId != null && stageId != null && assignmentId != null) {
        final response = await ApiService.getStageInventoryAllocations(workOrderId, stageId);
        if (response["success"] == true && response["data"] != null) {
          final allAllocations = (response["data"] as List).cast<Map<String, dynamic>>();
          // Filter allocations for this worker assignment
          final filtered = allAllocations.where((alloc) {
            final allocAssignmentId = alloc['worker_assignment_id'];
            if (allocAssignmentId == null) return false;
            
            // Handle both cases: direct ID or relationship object
            String? allocIdStr;
            if (allocAssignmentId is Map) {
              allocIdStr = allocAssignmentId['id']?.toString();
            } else {
              allocIdStr = allocAssignmentId.toString();
            }
            
            return allocIdStr == assignmentId;
          }).toList();

          setState(() {
            inventoryAllocations = filtered;
            // Initialize controllers for each allocation
            for (var alloc in inventoryAllocations) {
              final allocId = alloc['id']?.toString() ?? '';
              if (allocId.isNotEmpty) {
                returnedControllers[allocId] = TextEditingController(text: '0');
                brokenControllers[allocId] = TextEditingController(text: '0');
              }
            }
            isLoadingInventory = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading inventory allocations: $e');
    }
    setState(() {
      isLoadingInventory = false;
    });
  }

  @override
  void dispose() {
    outputController.dispose();
    rejectedController.dispose();
    notesController.dispose();
    for (var controller in returnedControllers.values) {
      controller.dispose();
    }
    for (var controller in brokenControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final outputQty = int.tryParse(outputController.text) ?? 0;
    final rejectedQty = int.tryParse(rejectedController.text) ?? 0;

    if (outputQty <= 0) {
      Get.snackbar("Error", "Output quantity must be > 0",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Submit work assignment
      final response = await ApiService.submitWorkerAssignment(
        widget.assignment['id'].toString(),
        {
          'worker_output_quantity': outputQty,
          'rejected_quantity': rejectedQty,
          'worker_notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        },
      );

      if (response["success"] != true) {
        throw Exception(response["error"] ?? "Failed to submit work");
      }

      // Submit inventory returns if any
      for (var alloc in inventoryAllocations) {
        final allocId = alloc['id']?.toString() ?? '';
        final returnedController = returnedControllers[allocId];
        final brokenController = brokenControllers[allocId];

        if (returnedController != null && brokenController != null) {
          final quantityReturned = int.tryParse(returnedController.text) ?? 0;
          final quantityBrokenLost = int.tryParse(brokenController.text) ?? 0;

          if (quantityReturned > 0 || quantityBrokenLost > 0) {
            try {
              await ApiService.returnWorkerInventory(allocId, {
                'quantity_returned': quantityReturned,
                'quantity_broken_lost': quantityBrokenLost,
                'worker_notes': notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              });
            } catch (e) {
              print('Error returning inventory $allocId: $e');
              // Continue with other returns even if one fails
            }
          }
        }
      }

      Get.snackbar("Success", "Work submitted successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to submit work: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingInventory) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        content: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: const Text(
        "Submit Work",
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: outputController,
              decoration: InputDecoration(
                labelText: "Output Quantity *",
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
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rejectedController,
              decoration: InputDecoration(
                labelText: "Rejected Quantity",
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
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: "Notes (Optional)",
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
              ),
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
            ),
            // Inventory return section
            if (inventoryAllocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text(
                "Return Inventory",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...inventoryAllocations.map((alloc) {
                final allocId = alloc['id']?.toString() ?? '';
                // Handle inventory_id as either direct object or relationship
                final inventoryData = alloc['inventory_id'];
                String inventoryName = 'Inventory Item';
                if (inventoryData != null) {
                  if (inventoryData is Map) {
                    inventoryName = inventoryData['name']?.toString() ?? 
                                   inventoryData['fabric']?.toString() ?? 
                                   inventoryData['id']?.toString() ?? 
                                   'Inventory Item';
                  } else {
                    inventoryName = inventoryData.toString();
                  }
                }
                final quantityProvided = alloc['quantity_provided'] ?? 0;
                final returnedController = returnedControllers[allocId] ?? TextEditingController(text: '0');
                final brokenController = brokenControllers[allocId] ?? TextEditingController(text: '0');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F111A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventoryName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Provided: $quantityProvided",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: returnedController,
                              decoration: InputDecoration(
                                labelText: "Returned",
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: const Color(0xFF1E1E2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: brokenController,
                              decoration: InputDecoration(
                                labelText: "Broken/Lost",
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: const Color(0xFF1E1E2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.black,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
}
