import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/services/api_service.dart';

class StageSubmissionsView extends StatefulWidget {
  final String workOrderId;
  final String stageId;
  final String stageName;
  final VoidCallback onSuccess;

  const StageSubmissionsView({
    super.key,
    required this.workOrderId,
    required this.stageId,
    required this.stageName,
    required this.onSuccess,
  });

  @override
  State<StageSubmissionsView> createState() => _StageSubmissionsViewState();
}

class _StageSubmissionsViewState extends State<StageSubmissionsView> {
  List<dynamic> _submissions = [];
  bool _isLoading = false;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getStageSubmissions(
        widget.workOrderId,
        widget.stageId,
      );
      if (response["success"] == true && response["data"] != null) {
        setState(() {
          _submissions = response["data"] as List;
        });
      } else {
        Get.snackbar("Error", response["error"] ?? "Failed to load submissions",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load submissions: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveSubmission(Map<String, dynamic> submission) async {
    final approvedController = TextEditingController(
        text: submission['worker_output_quantity']?.toString() ?? '0');
    final rejectedController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text(
            "Approve Submission",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Worker: ${submission['worker']?['name'] ?? 'Unknown'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: approvedController,
                  decoration: InputDecoration(
                    labelText: "Approved Quantity *",
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
                    labelText: "Admin Notes (Optional)",
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final approvedQty =
                          int.tryParse(approvedController.text) ?? 0;
                      final rejectedQty =
                          int.tryParse(rejectedController.text) ?? 0;

                      if (approvedQty < 0) {
                        Get.snackbar("Error", "Approved quantity must be >= 0",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100);
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        final response =
                            await ApiService.approveWorkerAssignment(
                          submission['id']?.toString() ??
                              submission['assignment_id']?.toString() ??
                              '',
                          {
                            'approved_quantity': approvedQty,
                            'rejected_quantity': rejectedQty,
                            'admin_notes': notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            'status': 'approved',
                          },
                        );

                        if (response["success"] == true) {
                          Get.snackbar("Success", "Submission approved",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade100);
                          Navigator.of(context).pop();
                          _loadSubmissions();
                        } else {
                          throw Exception(
                              response["error"] ?? "Failed to approve submission");
                        }
                      } catch (e) {
                        Get.snackbar("Error", "Failed to approve: $e",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100);
                      } finally {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Approve"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectSubmission(Map<String, dynamic> submission) async {
    final rejectedController = TextEditingController(
        text: submission['worker_output_quantity']?.toString() ?? '0');
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text(
            "Reject Submission",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Worker: ${submission['worker']?['name'] ?? 'Unknown'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rejectedController,
                  decoration: InputDecoration(
                    labelText: "Rejected Quantity *",
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
                    labelText: "Rejection Reason *",
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (notesController.text.trim().isEmpty) {
                        Get.snackbar("Error", "Rejection reason is required",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100);
                        return;
                      }

                      final rejectedQty =
                          int.tryParse(rejectedController.text) ?? 0;

                      setDialogState(() => isSubmitting = true);

                      try {
                        final response =
                            await ApiService.approveWorkerAssignment(
                          submission['id']?.toString() ??
                              submission['assignment_id']?.toString() ??
                              '',
                          {
                            'approved_quantity': 0,
                            'rejected_quantity': rejectedQty,
                            'admin_notes': notesController.text.trim(),
                            'status': 'rejected',
                          },
                        );

                        if (response["success"] == true) {
                          Get.snackbar("Success", "Submission rejected",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orange.shade100);
                          Navigator.of(context).pop();
                          _loadSubmissions();
                        } else {
                          throw Exception(
                              response["error"] ?? "Failed to reject submission");
                        }
                      } catch (e) {
                        Get.snackbar("Error", "Failed to reject: $e",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100);
                      } finally {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Reject"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finalizeStage() async {
    final allApproved = _submissions.every((s) => s['status'] == 'approved');
    if (!allApproved) {
      Get.snackbar("Error", "All submissions must be approved before finalizing",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Finalize Stage",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to finalize this stage? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: const Text("Finalize"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isFinalizing = true);

    try {
      final response = await ApiService.finalizeStage(
        widget.workOrderId,
        widget.stageId,
      );

      if (response["success"] == true) {
        Get.snackbar("Success", "Stage finalized successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100);
        widget.onSuccess();
        Get.back();
      } else {
        throw Exception(response["error"] ?? "Failed to finalize stage");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to finalize stage: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isFinalizing = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allApproved = _submissions.isNotEmpty &&
        _submissions.every((s) => s['status'] == 'approved');

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: Text(
          "Submissions - ${widget.stageName.toUpperCase()}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (allApproved)
            IconButton(
              icon: _isFinalizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
              onPressed: _isFinalizing ? null : _finalizeStage,
              tooltip: "Finalize Stage",
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No submissions found",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadSubmissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                        ),
                        child: const Text("Refresh"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) {
                      final submission = _submissions[index];
                      final status = submission['status'] as String? ?? 'submitted';
                      final statusColor = _getStatusColor(status);
                      final worker = submission['worker'] ?? submission['workers_id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: const Color(0xFF1E1E2E),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker?['name'] ?? 'Unknown Worker',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (worker?['email'] != null)
                                          Text(
                                            worker['email'],
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: statusColor, width: 1),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Assigned",
                                      "${submission['assigned_quantity'] ?? submission['quantity'] ?? 0}",
                                      Icons.assignment,
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Worker Output",
                                      "${submission['worker_output_quantity'] ?? 0}",
                                      Icons.check_circle_outline,
                                      Colors.orange,
                                    ),
                                  ),
                                  if (submission['admin_approved_quantity'] !=
                                      null)
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Approved",
                                        "${submission['admin_approved_quantity']}",
                                        Icons.verified,
                                        Colors.green,
                                      ),
                                    ),
                                  if (submission['admin_rejected_quantity'] !=
                                      null &&
                                      (submission['admin_rejected_quantity'] as int) > 0)
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Rejected",
                                        "${submission['admin_rejected_quantity']}",
                                        Icons.cancel,
                                        Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                              if (submission['worker_notes'] != null &&
                                  submission['worker_notes'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.note,
                                                color: Colors.grey, size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              "Worker Notes:",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          submission['worker_notes'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (submission['admin_notes'] != null &&
                                  submission['admin_notes'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.admin_panel_settings,
                                                color: Colors.grey, size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              "Admin Notes:",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          submission['admin_notes'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (status == 'submitted')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _rejectSubmission(submission),
                                          icon: const Icon(Icons.cancel,
                                              size: 18),
                                          label: const Text("Reject"),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _approveSubmission(submission),
                                          icon: const Icon(Icons.check,
                                              size: 18),
                                          label: const Text("Approve"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

