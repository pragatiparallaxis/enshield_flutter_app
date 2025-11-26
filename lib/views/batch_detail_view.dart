import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/batch_detail/batch_detail_viewmodel.dart';
import 'package:enshield_app/models/batch_model.dart';
import 'package:enshield_app/models/production_stage_model.dart';
import 'package:enshield_app/widgets/allocate_material_modal.dart';
class BatchDetailView extends StatelessWidget {
  final String batchId;

  const BatchDetailView({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BatchDetailViewModel(batchId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text(
          "Batch Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.isActionLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF9800),
                    ),
                  ),
                ),
              );
            }

            final batch = controller.batch.value;
            if (batch?.status == 'pending') {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton.icon(
                  onPressed: controller.startBatch,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text("Start Batch"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
            ),
          );
        }

        final batch = controller.batch.value;
        if (batch == null) {
          return const Center(
            child: Text(
              "Batch not found",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBatchHeader(batch, controller),
              const SizedBox(height: 16),
              _buildBatchInfo(batch),
              const SizedBox(height: 16),
              _buildStageProgress(context, controller),

              const SizedBox(height: 16),
              _buildProductPieces(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBatchHeader(BatchModel batch, BatchDetailViewModel controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.name ?? batch.batchCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  batch.batchCode,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(batch.status),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${batch.plannedQuantity} units",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Planned Quantity",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final finalOutput = controller.getFinalOutputQuantity();
                if (finalOutput > 0) {
                  return Column(
                    children: [
                      Text(
                        "$finalOutput units",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Final Output",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Color(0xFFFF9800);
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _buildPieceDisplay(ProductPiece? piece) {
    if (piece == null) return "Unknown Piece";
    
    final List<String> parts = [piece.pieceCode];
    
    if (piece.name != null && piece.name!.isNotEmpty) {
      parts.add(piece.name!);
    } else if (piece.size.isNotEmpty) {
      parts.add(piece.size);
    }
    
    if (piece.componentType != null && piece.componentType!.isNotEmpty) {
      parts.add(piece.componentType!);
    }
    
    if (piece.quantity != null && piece.quantity! > 0) {
      parts.add('qty: ${piece.quantity}');
    }
    
    return parts.join(' • ');
  }

  Widget _buildBatchInfo(BatchModel batch) {
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
            "Batch Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Work Order", batch.workOrder?.title ?? "N/A"),
          _buildInfoRow("Product", batch.product?.name ?? "N/A"),
          _buildInfoRow("Assigned To", batch.assignedTo ?? "Unassigned"),
          _buildInfoRow(
            "Created",
            batch.createdDate?.toString().split(' ')[0] ?? "N/A",
          ),
          if (batch.notes != null && batch.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              "Notes:",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(batch.notes!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
Widget _buildStageProgress(BuildContext context, BatchDetailViewModel controller) {

  return DefaultTabController(
    length: 2, // Two tabs: Production Stages & Materials
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            indicatorColor: Color(0xFFFF9800),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Production Stages"),
              Tab(text: "Materials"),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300, // adjust based on design
            child: TabBarView(
              children: [
                // --- Production Stages Tab ---
                controller.productionStages.isEmpty
                    ? const Center(
                        child: Text(
                          "No production stages found",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        children: controller.productionStages.map((stage) {
                          final progress = controller.stageProgress.firstWhereOrNull(
                            (p) => p.stageId == stage.id,
                          );
                          return _buildStageCard(stage, progress, controller);
                        }).toList(),
                      ),

                // --- Materials Tab ---
            _buildMaterialTab(controller, context),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMaterialTab(BatchDetailViewModel controller, BuildContext context) {
  final materials = controller.materials;
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 600;

  if (materials.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 60),
            const SizedBox(height: 12),
            const Text(
              "No materials allocated",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              "Materials haven't been allocated for this batch yet.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFFFF6F00),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AllocateMaterialsModal(batchId: controller.batchId),
                ).then((result) {
                  if (result == true) controller.loadMaterials();
                });
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Allocate Material",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFFFF6F00),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
               backgroundColor: const Color(0xFFFF6F00),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => AllocateMaterialsModal(batchId: controller.batchId),
              ).then((result) {
                if (result == true) controller.loadMaterials();
              });
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Allocate Materials",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Material list
        ...materials.map((material) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F111A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.deepOrangeAccent.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Name
                Text(
                  material.name ?? "Unnamed Material",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                const SizedBox(height: 4),

                // Ratio per piece only
                Text(
                  "Ratio: ${material.ratioPerPiece ?? 0} per piece",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );
}

  Widget _buildStageCard(
    ProductionStageModel stage,
    BatchStageProgress? progress,
    BatchDetailViewModel controller,
  ) {
    final status = progress?.status ?? 'not_started';
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case 'pending':
        statusColor = Color(0xFFFF9800);
        statusIcon = Icons.schedule;
        break;
      case 'not_started':
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (stage.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stage.description!,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Input: ${progress.inputQuantity} | Output: ${progress.outputQuantity} | Rejected: ${progress.rejectedQuantity}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if ((progress.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Notes: ${progress.notes}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                  if (progress.assignedUser != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Assigned: ${progress.assignedUser}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                  if (progress.outsourcedVendor != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Vendor: ${progress.outsourcedVendor}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                  if (progress.completedByUser != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Completed by: ${progress.completedByUser}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (status == 'pending')
            ElevatedButton(
              onPressed: () => _showStartStageDialog(stage, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text(
                "Start",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (status == 'in_progress')
            ElevatedButton(
              onPressed: () => _showCompleteStageDialog(progress!, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text(
                "Complete",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductPieces(BatchDetailViewModel controller) {
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
            "Product Pieces",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (controller.productPieces.isEmpty)
            const Center(
              child: Text(
                "No pieces available",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...controller.productPieces.map((piece) => _buildPieceCard(piece)),
        ],
      ),
    );
  }

  Widget _buildPieceCard(ProductPiece piece) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  piece.pieceCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${piece.name ?? piece.size} • Qty: ${piece.quantity ?? 1}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPieceStatusColor(piece.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              piece.status.toUpperCase(),
              style: TextStyle(
                color: _getPieceStatusColor(piece.status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPieceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'defective':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'scrapped':
        return Colors.grey;
      default:
        return Color(0xFFFF9800);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showStartStageDialog(
    ProductionStageModel stage,
    BatchDetailViewModel controller,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          "Start ${stage.name}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to start the ${stage.name} stage?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.startStage(stage.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF9800)),
            child: const Text(
              "Start Stage",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteStageDialog(
    BatchStageProgress stage,
    BatchDetailViewModel controller,
  ) async {
    await controller.initializeStageCompletion(stage);

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Complete ${stage.stageName}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Stage Info ---
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
                          "Stage: ${stage.stageName}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                              "Input Quantity: ${controller.inputQuantity.value}",
                              style: const TextStyle(color: Colors.grey),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Input & Rejected Quantity ---
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Output Quantity",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() => Text(
                                  "${controller.inputQuantity.value}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rejected Quantity",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "0",
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F111A),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                controller.updateRejectedQuantity(
                                  int.tryParse(value) ?? 0,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Outsourced Vendor Dropdown ---
                  const Text(
                    "Outsourced Vendor (Optional)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String?>(
                      value: controller.outsourcedVendorId.value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F111A),
                      ),
                      dropdownColor: const Color(0xFF1E1E2E),
                      style: const TextStyle(color: Colors.white),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            "Internal (No Vendor)",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ...controller.outsourcedParties
                            .map(
                              (party) => DropdownMenuItem(
                                value: party.id,
                                child: Text(
                                  "${party.name} - ${party.serviceType}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (value) =>
                          controller.updateOutsourcedVendor(value),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Completed By ---
                  const Text(
                    "Completed By",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.completedBy.value.isNotEmpty
                          ? controller.completedBy.value
                          : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F111A),
                      ),
                      dropdownColor: const Color(0xFF1E1E2E),
                      style: const TextStyle(color: Colors.white),
                      items: controller.appUsers
                          .map(
                            (user) => DropdownMenuItem(
                              value: user.id!,
                              child: Text(
                                "${user.firstName} ${user.lastName}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          controller.updateCompletedBy(value ?? ''),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Notes ---
                  const Text(
                    "Notes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Optional notes about this stage completion",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F111A),
                    ),
                    maxLines: 3,
                    onChanged: (value) => controller.updateNotes(value),
                  ),
                  const SizedBox(height: 20),

                  // --- Per-Piece Breakdown ---
                  const Text(
                    "Per-Piece Breakdown",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (controller.perPieces.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "No product pieces available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.perPieces.length,
                      itemBuilder: (context, index) {
                        final pieceData = controller.perPieces[index];
                        final piece = controller.productPieces.firstWhereOrNull(
                          (p) => p.id == pieceData['piece_id'],
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F111A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _buildPieceDisplay(piece),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Available: ${controller.getAvailableForPiece((piece?.id ?? '').toString())}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Obx(() {
                                      final outputValue = controller.perPieces[index]['processed_output'] ?? 0;
                                      return TextField(
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Output",
                                          labelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1E1E2E),
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(
                                          text: outputValue.toString(),
                                        ),
                                        onChanged: (value) =>
                                            controller.updatePerPieceOutput(
                                              index,
                                              int.tryParse(value) ?? 0,
                                            ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Obx(() {
                                      final rejectedValue = controller.perPieces[index]['processed_rejected'] ?? 0;
                                      return TextField(
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Rejected",
                                          labelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1E1E2E),
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(
                                          text: rejectedValue.toString(),
                                        ),
                                        onChanged: (value) =>
                                            controller.updatePerPieceRejected(
                                              index,
                                              int.tryParse(value) ?? 0,
                                            ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 20),

                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await controller.completeStage(stage);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          "Complete Stage",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
