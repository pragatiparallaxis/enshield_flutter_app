import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AllocateMaterialsModal extends StatefulWidget {
  final String batchId; // ✅ Receive from parent screen

  const AllocateMaterialsModal({super.key, required this.batchId});

  @override
  State<AllocateMaterialsModal> createState() => _AllocateMaterialsModalState();
}

class _AllocateMaterialsModalState extends State<AllocateMaterialsModal> {
  List<Map<String, dynamic>> materials = [
    {'material': null, 'ratio': '', 'notes': ''}
  ];

  List<dynamic> inventoryList = [];
  bool isLoading = true;
  bool isSubmitting = false;

  final darkBg = const Color(0xFF1A1D2A);
  final fieldBg = const Color(0xFF0F111A);
  final orange = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    fetchInventoryList();
  }

  /// ✅ Fetch Materials (Inventory)
  Future<void> fetchInventoryList() async {
    try {
      const baseUrl = 'http://185.165.240.191:3056';
      final storage = GetStorage();
      final token = storage.read('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          setState(() {
            inventoryList = data["data"];
            isLoading = false;
          });
        }
      } else {
        print("❌ Failed to load inventory: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ Error fetching inventory: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Allocate Materials API Call
  Future<void> allocateMaterials() async {
    try {
      setState(() => isSubmitting = true);
      const baseUrl = 'http://185.165.240.191:3056';
      final storage = GetStorage();
      final token = storage.read('auth_token') ?? '';

      // Format the body as per API requirements
      final body = {
        "materialAllocations": materials
            .where((m) => m['material'] != null && m['ratio'].toString().isNotEmpty)
            .map((m) => {
                  "inventory_id": m['material'],
                  "ratio_per_piece": double.tryParse(m['ratio']) ?? 0,
                  "notes": m['notes'] ?? '',
                })
            .toList(),
      };

      print("📤 Sending request to: $baseUrl/api/production/batches/${widget.batchId}/allocate-materials");
      print("📝 Request body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$baseUrl/api/production/batches/${widget.batchId}/allocate-materials'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("📥 Response status: ${response.statusCode}");
      print("📦 Raw Response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Get.back(result: true); // ✅ Return true to refresh parent
        Get.snackbar(
          "Success",
          "Materials allocated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to allocate materials.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      Get.snackbar(
        "Error",
        "Error allocating materials: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Allocate Materials to Batch",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Material Fields
                      ...materials.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    flex: 3,
                                    fit: FlexFit.tight,
                                    child: DropdownButtonFormField<String>(
                                      value: item['material'],
                                      dropdownColor: fieldBg,
                                      decoration: InputDecoration(
                                        labelText: "Material",
                                        labelStyle: const TextStyle(color: Colors.grey),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      ),
                                      items: inventoryList.map((mat) {
                                        return DropdownMenuItem<String>(
                                          value: mat['id'],
                                          child: Text(
                                            mat['name'] ?? 'Unnamed',
                                            style: const TextStyle(color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          materials[index]['material'] = val;
                                        });
                                      },
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    flex: 2,
                                    fit: FlexFit.tight,
                                    child: TextFormField(
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Ratio",
                                        labelStyle: const TextStyle(color: Colors.grey),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      ),
                                      onChanged: (val) => materials[index]['ratio'] = val,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Notes (optional)",
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: fieldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (val) =>
                                    materials[index]['notes'] = val,
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Material Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              materials.add(
                                  {'material': null, 'ratio': '', 'notes': ''});
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Add Material",
                              style: TextStyle(color: Colors.white)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade700),
                              ),
                              child: const Text("Cancel",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  isSubmitting ? null : allocateMaterials, // ✅ API call
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Allocate Materials",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
        );
      },
    );
  }
}
