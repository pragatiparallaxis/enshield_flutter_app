import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:enshield_app/viewmodels/dashboard/dashboard_viewmodel.dart';
import 'package:enshield_app/views/work_order_create.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/routes.dart';
import 'package:enshield_app/services/auth_service.dart'; // Added import for AuthService

class ProductionDashboardView extends StatelessWidget {
  const ProductionDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductionDashboardViewModel());

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),

      // ✅ Drawer attached here
      drawer: Builder(
        builder: (context) {
          final storage = GetStorage();
          final userRole = storage.read('user_role')?.toString().toUpperCase() ?? 'APP_USER';
          final isAdmin = userRole == 'APP_ADMIN';

          return Drawer(
            child: Column(
              children: [
                SizedBox(height:45),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                // Only show admin features for APP_ADMIN
                if (isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: const Text('Inventory'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(Routes.inventory);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Outsourced Parties'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed('/outsourced-parties');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Workers'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed('/workers');
                    },
                  ),
                ],
                // Show worker assignments for all users
                if (!isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: const Text('My Assignments'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(Routes.workerAssignments);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // open settings
                  },
                ),
                const Spacer(), // pushes logout to bottom
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    // ✅ show confirm dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // close dialog
                              Navigator.pop(context); // close drawer

                              // Replace logout logic with AuthService.logout()
                              AuthService.logout();
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white), // 🍔 menu icon
            onPressed: () {
              Scaffold.of(context).openDrawer(); // ✅ open the drawer
            },
          ),
        ),
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Get.to(() => CreateWorkOrderView()),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "New Work Order",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monitor and manage your production workflow",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _statsGrid(controller),
            const SizedBox(height: 20),
            _recentWorkOrders(controller),
          ],
        ),
      ),
    );
  }

  /// ✅ Responsive grid for stats (no overflow)
  Widget _statsGrid(ProductionDashboardViewModel controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        children: [
          _statCard(
            "Total Work Orders",
            "${controller.totalWorkOrders.value}",
            "Active work orders",
          ),
          _statCard(
            "Total Batches",
            "${controller.totalBatches.value}",
            "Ongoing batches",
          ),
          _statCard(
            "Efficiency Rate",
            "${controller.efficiencyRate.value.toStringAsFixed(2)}%",
            "Output/input ratio",
          ),
          _statCard(
            "Avg Completion Time",
            "${controller.avgCompletionTime.value.toStringAsFixed(1)}h",
            "Per work order",
          ),
        ],
      );
    });
  }

  Widget _statCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recentWorkOrders(ProductionDashboardViewModel controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Work Orders",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Work Orders List (No Tabs)
          Obx(() {
            final workOrders = controller.allWorkOrders;
            return Column(
              children: workOrders
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${order.work_order_code} • ${order.planned_quantity} units",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _buildStatusChip(order.status),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _actionButton(
                                Icons.visibility,
                                "",
                                () => controller.viewOrder(order),
                              ),
                              const SizedBox(width: 8),
                              _actionButton(
                                Icons.edit,
                                "",
                                () => controller.editOrder(order),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'In Progress';
        break;
      case 'pending':
        color = Color(0xFFFF9800);
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A2D3E),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
