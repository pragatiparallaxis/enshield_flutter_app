import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/outsourced_party/outsourced_party_list_viewmodel.dart';
import 'package:enshield_app/views/outsourced_party_create.dart';

class OutsourcedPartyListView extends StatelessWidget {
  const OutsourcedPartyListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OutsourcedPartyListViewModel());

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text(
          "Outsourced Parties",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Get.to(() => const CreateOutsourcedPartyView());
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                "Add Party",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
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

        final filteredParties = controller.filteredParties;

        if (controller.outsourcedParties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business_outlined,
                  color: Colors.grey,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No Outsourced Parties",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Start by adding your first outsourced party",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const CreateOutsourcedPartyView());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add First Party",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildTabButton("All", 0, controller),
                  _buildTabButton("Active", 1, controller),
                  _buildTabButton("Inactive", 2, controller),
                ],
              ),
            ),

            // Party List
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadOutsourcedParties,
                color: const Color(0xFFFF9800),
                child: filteredParties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              color: Colors.grey,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No Parties Found",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() => Text(
                                  controller.selectedTabIndex.value == 1
                                      ? "No active parties"
                                      : controller.selectedTabIndex.value == 2
                                          ? "No inactive parties"
                                          : "No parties found",
                                  style: const TextStyle(color: Colors.grey),
                                )),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredParties.length,
                        itemBuilder: (context, index) {
                          final party = filteredParties[index];
                          return _buildPartyCard(party, controller);
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton(String label, int index, OutsourcedPartyListViewModel controller) {
    return Obx(() {
      final isSelected = controller.selectedTabIndex.value == index;

      return Expanded(
        child: GestureDetector(
          onTap: () => controller.updateSelectedTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF9800) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPartyCard(party, OutsourcedPartyListViewModel controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: party.isActive 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        party.serviceType,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: party.isActive 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  party.isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    color: party.isActive ? Colors.green : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Contact info
          if (party.contact != null && party.contact!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  party.contact!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Rate info
          if (party.rate != null) ...[
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Rate: ${party.rate!.toStringAsFixed(2)} per piece",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Notes
          if (party.notes != null && party.notes!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    party.notes!,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.editParty(party),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2D3E),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.togglePartyStatus(party),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: party.isActive 
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: Icon(
                    party.isActive ? Icons.pause : Icons.play_arrow,
                    color: party.isActive ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  label: Text(
                    party.isActive ? "Deactivate" : "Activate",
                    style: TextStyle(
                      color: party.isActive ? Colors.red : Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
