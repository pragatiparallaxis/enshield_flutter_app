import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/workorder/work_order_viewmodel.dart';
import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/widgets/allocate_materials_work_order_modal.dart';
import 'package:enshield_app/widgets/complete_stage_modal.dart';
import 'package:enshield_app/widgets/assign_workers_modal.dart';
import 'package:enshield_app/widgets/return_layers_modal.dart';
import 'package:enshield_app/widgets/edit_allocation_modal.dart';
import 'package:enshield_app/views/stage_submissions_view.dart';

class WorkOrderView extends StatefulWidget {
  final String workOrderId;
  const WorkOrderView({super.key, required this.workOrderId});

  @override
  State<WorkOrderView> createState() => _WorkOrderViewState();
}

class _WorkOrderViewState extends State<WorkOrderView> {
  WorkOrderItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkOrderViewModel(widget.workOrderId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text(
          "Work Order Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed('/dashboard');
            }
          },
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final workOrder = controller.workOrder.value;
        if (workOrder == null) {
          return const Center(
            child: Text("No data found", style: TextStyle(color: Colors.white)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(workOrder),
                const SizedBox(height: 16),

                // Stats Cards
                _buildStatsCards(workOrder),
                const SizedBox(height: 16),

                // Work Order Details & Material Allocations
                Row(
                  children: [
                    Expanded(child: _buildDetailsCard(workOrder)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInventoryCard(workOrder, controller)),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Order Items & Stages
                _buildItemsAndStagesCard(workOrder, controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(WorkOrder workOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workOrder.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workOrder.work_order_code,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(workOrder.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              workOrder.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(workOrder.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(WorkOrder workOrder) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Planned Quantity',
            workOrder.planned_quantity.toString(),
            'units',
            Icons.inventory_2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Items',
            (workOrder.work_order_items?.length ?? 0).toString(),
            'combinations',
            Icons.category,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Materials',
            (workOrder.inventory?.length ?? 0).toString(),
                  'allocations',
                  Icons.content_cut,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6F00), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(WorkOrder workOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Work Order Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow("Work Order Code", workOrder.work_order_code),
          if (workOrder.client_name != null)
            _infoRow("Client", workOrder.client_name!),
          if (workOrder.order_date != null)
            _infoRow("Order Date", workOrder.order_date?.toString() ?? 'N/A'),
          if (workOrder.notes != null && workOrder.notes!.isNotEmpty)
            _infoRow("Notes", workOrder.notes!),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(WorkOrder workOrder, WorkOrderViewModel controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  "Material Allocations",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
        await showDialog(
          context: Get.context!,
          builder: (context) => AllocateMaterialsWorkOrderModal(
            workOrderId: widget.workOrderId,
            onSuccess: () => controller.refresh(),
          ),
        );
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text("Allocate", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (workOrder.inventory != null && workOrder.inventory!.isNotEmpty)
            ...workOrder.inventory!.map((inv) => _buildInventoryItem(inv))
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No materials allocated yet",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(WorkOrderInventory inv) {
    final layersUsed = inv.layers_used ?? 0;
    final layersReturned = inv.layers_returned ?? 0;
    final effectiveLayers = layersUsed - layersReturned;
    final canReturnLayers = effectiveLayers > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    inv.color ?? 'N/A',
                    style: const TextStyle(color: Color(0xFFFF6F00)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "${inv.total_meters}m / ${inv.table_length}m table",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Layers: ${layersUsed} / ${inv.layers_calculated != null ? inv.layers_calculated!.toStringAsFixed(1) : '0'}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (layersReturned > 0)
                      Text(
                        "Returned: ${layersReturned.toStringAsFixed(1)}",
                        style: const TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    Text(
                      "Effective: $effectiveLayers",
                      style: TextStyle(
                        color: effectiveLayers > 0 ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  "Output: ${inv.output_quantity ?? 0} pieces",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          if (inv.categories != null && inv.categories!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Categories: ${inv.categories!.map((c) => c.name).join(', ')}",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
          if (inv.sizes != null && inv.sizes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              "Sizes: ${inv.sizes!.map((s) => s.name).join(', ')}",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (canReturnLayers)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final controller = Get.find<WorkOrderViewModel>();
                      showDialog(
                        context: context,
                        builder: (context) => ReturnLayersModal(
                          inventory: inv,
                          onSuccess: () {
                            controller.refresh();
                          },
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF6F00)),
                      foregroundColor: const Color(0xFFFF6F00),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.undo, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Return Layers',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canReturnLayers) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final controller = Get.find<WorkOrderViewModel>();
                    showDialog(
                      context: context,
                      builder: (context) => EditAllocationModal(
                        workOrderId: widget.workOrderId,
                        inventory: inv,
                        onSuccess: () {
                          controller.refresh();
                        },
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Edit Allocation',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsAndStagesCard(WorkOrder workOrder, WorkOrderViewModel controller) {
    final stages = ['cutting', 'sorting', 'stitching', 'finishing', 'ironing', 'packing'];
    final items = workOrder.work_order_items ?? [];

    // Find the current selected item from the items list by ID
    WorkOrderItem? currentSelectedItem;
    if (selectedItem != null && items.isNotEmpty) {
      try {
        currentSelectedItem = items.firstWhere((item) => item.id == selectedItem!.id);
      } catch (e) {
        // Selected item not found, will auto-select first item
        currentSelectedItem = null;
      }
    }

    // Auto-select first item if none selected and items exist
    if (currentSelectedItem == null && items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedItem = items.first;
        });
      });
      currentSelectedItem = items.first;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Work Order Items & Stages",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isNotEmpty) ...[
            // Dropdown to select work order item
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F111A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonFormField<WorkOrderItem>(
                value: currentSelectedItem,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                dropdownColor: const Color(0xFF1E1E2E),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: items.map((item) {
                  final stageInfo = _getCurrentStageInfo(item);
                  final currentStage = stageInfo['stage'] as String;
                  final stageColor = stageInfo['color'] as Color;
                  return DropdownMenuItem<WorkOrderItem>(
                    value: item,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${item.color} ${item.category} - Size ${item.size}",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stageColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: stageColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            currentStage.toUpperCase(),
                            style: TextStyle(
                              color: stageColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (WorkOrderItem? newItem) {
                  setState(() {
                    selectedItem = newItem;
                  });
                },
                selectedItemBuilder: (BuildContext context) {
                  return items.map((item) {
                    final stageInfo = _getCurrentStageInfo(item);
                    final currentStage = stageInfo['stage'] as String;
                    final stageColor = stageInfo['color'] as Color;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${item.color} ${item.category} - Size ${item.size}",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stageColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: stageColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            currentStage.toUpperCase(),
                            style: TextStyle(
                              color: stageColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
            const SizedBox(height: 16),
            // Display selected item's details and stages
            if (currentSelectedItem != null)
              _buildItemCard(currentSelectedItem!, stages, controller),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No items created yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Allocate materials for cutting stage to create work order items.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrentStageInfo(WorkOrderItem item) {
    final stages = ['cutting', 'sorting', 'stitching', 'finishing', 'ironing', 'packing'];
    final itemStages = item.work_order_stages ?? [];

    // First, find the latest stage that is in_progress
    for (int i = stages.length - 1; i >= 0; i--) {
      final stageName = stages[i];
      try {
        final stage = itemStages.firstWhere((s) => s.stage_name == stageName);
        if (stage.status == 'in_progress') {
          return {
            'stage': stageName,
            'color': Colors.blue,
            'status': 'in_progress',
          };
        }
        // Check for approved status (ready for finalization)
        if (stage.status == 'approved') {
          return {
            'stage': stageName,
            'color': Colors.green.shade300,
            'status': 'approved',
          };
        }
        // Check for submitted status (under review)
        if (stage.status == 'submitted') {
          return {
            'stage': stageName,
            'color': Colors.orange,
            'status': 'submitted',
          };
        }
      } catch (e) {
        // Stage not found, continue
        continue;
      }
    }

    // If no in_progress, find the latest completed stage
    for (int i = stages.length - 1; i >= 0; i--) {
      final stageName = stages[i];
      try {
        final stage = itemStages.firstWhere((s) => s.stage_name == stageName);
        if (stage.status == 'completed') {
          // Check if all stages are completed
          bool allCompleted = true;
          for (int j = 0; j <= i; j++) {
            try {
              final checkStage = itemStages.firstWhere((s) => s.stage_name == stages[j]);
              if (checkStage.status != 'completed') {
                allCompleted = false;
                break;
              }
            } catch (e) {
              allCompleted = false;
              break;
            }
          }
          if (allCompleted && i == stages.length - 1) {
            return {
              'stage': stageName,
              'color': Colors.green,
              'status': 'completed',
            };
          }
          // If not all completed, return the next pending stage
          if (i < stages.length - 1) {
            return {
              'stage': stages[i + 1],
              'color': Colors.orange,
              'status': 'pending',
            };
          }
        }
      } catch (e) {
        // Stage not found, continue
        continue;
      }
    }

    // If no stages exist or all are pending, return the first pending stage
    for (int i = 0; i < stages.length; i++) {
      final stageName = stages[i];
      try {
        final stage = itemStages.firstWhere((s) => s.stage_name == stageName);
        if (stage.status == 'pending') {
          return {
            'stage': stageName,
            'color': Colors.orange,
            'status': 'pending',
          };
        }
      } catch (e) {
        // Stage not found, return this stage as pending
        return {
          'stage': stageName,
          'color': Colors.orange,
          'status': 'pending',
        };
      }
    }

    // Default to first stage
    return {
      'stage': stages.first,
      'color': Colors.orange,
      'status': 'pending',
    };
  }

  Widget _buildItemCard(WorkOrderItem item, List<String> stages, WorkOrderViewModel controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${item.color} ${item.category} - Size ${item.size}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Planned: ${item.quantity} pieces",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Stages List (Single Column)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stageName = stages[index];
              final stageStatus = _getStageStatus(item, stageName);
              final stageData = _getStageData(item, stageName);
              final previousStageOutput = _getPreviousStageOutput(item, index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStageCard(
                  stageName,
                  stageStatus,
                  stageData,
                  previousStageOutput,
                  item,
                  controller,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(
    String stageName,
    String stageStatus,
    WorkOrderStage? stageData,
    int previousStageOutput,
    WorkOrderItem item,
    WorkOrderViewModel controller,
  ) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (stageStatus) {
      case 'completed':
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green;
        break;
      case 'approved':
        bgColor = Colors.green.shade300.withValues(alpha: 0.1);
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade300;
        break;
      case 'submitted':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        borderColor = Colors.orange;
        textColor = Colors.orange;
        break;
      case 'in_progress':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        borderColor = Colors.blue;
        textColor = Colors.blue;
        break;
      case 'assigned':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        borderColor = Colors.purple;
        textColor = Colors.purple;
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        borderColor = Colors.grey;
        textColor = Colors.grey;
    }

    return InkWell(
      onTap: () async {
        final workOrder = controller.workOrder.value;
        if (stageName == 'cutting' && (workOrder == null || (workOrder.inventory?.isEmpty ?? true))) {
          Get.snackbar(
            "Error",
            "Please allocate materials first",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
          );
          return;
        }
        await showDialog(
          context: Get.context!,
          builder: (context) => CompleteStageModal(
            workOrderId: widget.workOrderId,
            workOrderItem: item,
            stageName: stageName,
            stageOrder: _getStageOrder(stageName),
            onSuccess: () => controller.refresh(),
            existingStageData: stageData,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stageName.toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (stageStatus == 'completed')
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            // Input, Output, Rejected boxes
            Row(
              children: [
                Expanded(
                  child: _buildQuantityBox(
                    "Input",
                    (stageStatus == 'completed' || stageStatus == 'approved') && stageData != null
                        ? stageData.input_quantity.toString()
                        : previousStageOutput.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuantityBox(
                    "Output",
                    _getOutputQuantity(stageStatus, stageData),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuantityBox(
                    "Rejected",
                    _getRejectedQuantity(stageStatus, stageData),
                    Colors.red,
                  ),
                ),
              ],
            ),
            // Worker names
            if (stageStatus == 'completed' && stageData != null && stageData.worker_assignments != null && stageData.worker_assignments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stageData.worker_assignments!.map((assignment) {
                  final workerName = assignment.worker?.name ?? 'Unknown';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6F00),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      workerName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Notes
            if (stageStatus == 'completed' && stageData != null && stageData.notes != null && stageData.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stageData.notes!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            if (stageStatus == 'completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (stageStatus == 'approved')
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade300.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade300, width: 1),
                    ),
                    child: const Text(
                      'APPROVED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (stageData == null) {
                          Get.snackbar(
                            "Error",
                            "Stage data not found",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100,
                          );
                          return;
                        }
                        await Get.to(() => StageSubmissionsView(
                              workOrderId: widget.workOrderId,
                              stageId: stageData.id.toString(),
                              stageName: stageName,
                              onSuccess: () => controller.refresh(),
                            ));
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text("See Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              // Assign Workers button (for pending/assigned stages)
              if (stageStatus == 'pending' || stageStatus == 'assigned')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // If stage doesn't exist, we'll create it via the API
                      final stageId = stageData?.id ?? 'new';
                      final inputQty = stageData?.input_quantity ?? previousStageOutput;
                      final stageOrder = _getStageOrder(stageName);
                      
                      await showDialog(
                        context: Get.context!,
                        builder: (context) => AssignWorkersModal(
                          workOrderId: widget.workOrderId,
                          stageId: stageId.toString(),
                          workOrderItemId: item.id.toString(),
                          stageName: stageName,
                          inputQuantity: inputQty,
                          stageOrder: stageOrder,
                          onSuccess: () => controller.refresh(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text("Assign Workers"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              // View Submissions button (for submitted stages)
              if (stageStatus == 'submitted')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (stageData == null) {
                        Get.snackbar(
                          "Error",
                          "Stage data not found",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                        );
                        return;
                      }
                      await Get.to(() => StageSubmissionsView(
                            workOrderId: widget.workOrderId,
                            stageId: stageData.id.toString(),
                            stageName: stageName,
                            onSuccess: () => controller.refresh(),
                          ));
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text("View Submissions"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              // Complete Stage button (for assigned stages - legacy, now handled via submissions)
              if (stageStatus == 'assigned')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Complete Stage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStageStatus(WorkOrderItem item, String stageName) {
    final stages = item.work_order_stages ?? [];
    final stage = stages.firstWhere(
      (s) => s.stage_name == stageName,
      orElse: () => WorkOrderStage(
        id: 0,
        // work_order_id removed as it doesn't exist in model
        stage_name: stageName,
        stage_order: 0,
        input_quantity: 0,
        output_quantity: 0,
        rejected_quantity: 0,
        status: 'pending',
      ),
    );
    return stage.status;
  }

  String _getOutputQuantity(String stageStatus, WorkOrderStage? stageData) {
    if (stageStatus == 'completed' && stageData != null) {
      return stageData.output_quantity.toString();
    } else if (stageStatus == 'approved' && stageData != null) {
      // Calculate from approved assignments
      if (stageData.worker_assignments != null && stageData.worker_assignments!.isNotEmpty) {
        final totalApproved = stageData.worker_assignments!
            .where((a) => a.status == 'approved')
            .fold<int>(0, (sum, a) => sum + (a.admin_approved_quantity ?? 0));
        return totalApproved.toString();
      }
      return "0";
    }
    return "-";
  }

  String _getRejectedQuantity(String stageStatus, WorkOrderStage? stageData) {
    if (stageStatus == 'completed' && stageData != null) {
      return stageData.rejected_quantity.toString();
    } else if (stageStatus == 'approved' && stageData != null) {
      // Calculate from approved assignments
      if (stageData.worker_assignments != null && stageData.worker_assignments!.isNotEmpty) {
        final totalRejected = stageData.worker_assignments!
            .where((a) => a.status == 'approved')
            .fold<int>(0, (sum, a) => sum + 0); // admin_rejected_quantity not in model
        return totalRejected.toString();
      }
      return "0";
    }
    return "-";
  }

  WorkOrderStage? _getStageData(WorkOrderItem item, String stageName) {
    final stages = item.work_order_stages ?? [];
    try {
      return stages.firstWhere((s) => s.stage_name == stageName);
    } catch (e) {
      return null;
    }
  }

  int _getPreviousStageOutput(WorkOrderItem item, int currentStageIndex) {
    final stages = item.work_order_stages ?? [];
    final stageNames = ['cutting', 'sorting', 'stitching', 'finishing', 'ironing', 'packing'];

    if (currentStageIndex == 0) {
      return item.quantity;
    }

    for (int i = currentStageIndex - 1; i >= 0; i--) {
      final prevStageName = stageNames[i];
      try {
        final prevStage = stages.firstWhere(
          (s) => s.stage_name == prevStageName,
        );
        if (prevStage.status == 'completed') {
          return prevStage.output_quantity;
        }
      } catch (e) {
        // Stage not found, continue to next
        continue;
      }
    }

    return item.quantity;
  }

  int _getStageOrder(String stageName) {
    final stages = ['cutting', 'sorting', 'stitching', 'finishing', 'ironing', 'packing'];
    return stages.indexOf(stageName) + 1;
  }

  Widget _buildQuantityBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
