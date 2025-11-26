import 'package:get/get.dart';
import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/models/dashboard_model.dart';
import 'package:enshield_app/services/api_service.dart';
import 'package:enshield_app/views/work_order_view.dart';
import 'package:flutter/material.dart';

class ProductionDashboardViewModel extends GetxController {
  var totalWorkOrders = 0.obs;
  var totalBatches = 0.obs;
  var efficiencyRate = 0.0.obs;
  var avgCompletionTime = 0.0.obs;

  var recentWorkOrders = <WorkOrder>[].obs;
  var allWorkOrders = <WorkOrder>[].obs;
  var pendingWorkOrders = <WorkOrder>[].obs;
  var inProgressWorkOrders = <WorkOrder>[].obs;
  var completedWorkOrders = <WorkOrder>[].obs;
  var isLoading = false.obs;
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
    fetchWorkOrders();
  }

  /// 🟢 Fetch dashboard statistics from API
  Future<void> fetchDashboardStats() async {
    try {
      isLoading.value = true;

      final response = await ApiService.getProductionStats();

      print("🔍 API Response: $response"); // ✅ Debug print

      if (response["success"] == true && response["data"] != null) {
        final data = DashboardModel.fromJson(response["data"]);

        totalWorkOrders.value = data.totalWorkOrders;
        totalBatches.value = data.totalBatches;
        efficiencyRate.value = data.efficiencyRate;
        avgCompletionTime.value = data.averageCompletionTime;
      } else {
        Get.snackbar(
          "Error",
          response["message"] ?? "Failed to load dashboard stats",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }


  /// 🔹 Fetch work orders from API
  Future<void> fetchWorkOrders() async {
    try {
      isLoading.value = true;

      final response = await ApiService.getWorkOrders();

      print("🔍 Work Orders API Response: $response"); // ✅ Debug print

      if (response["success"] == true && response["data"] != null) {
        var workOrdersData = response["data"] as List;

        print("📦 Work Orders Data Count: ${workOrdersData.length}"); // ✅ Debug print

        // ✅ Map JSON to model with error handling
        final workOrdersList = <WorkOrder>[];
        
        for (var item in workOrdersData) {
          try {
            // Clean up the item - remove junction table arrays that are just IDs
            final cleanedItem = Map<String, dynamic>.from(item);
            
            // Remove junction table fields that are just IDs (not objects)
            if (cleanedItem['work_order_stages'] != null && 
                cleanedItem['work_order_stages'] is List &&
                (cleanedItem['work_order_stages'] as List).isNotEmpty &&
                (cleanedItem['work_order_stages'] as List).first is! Map) {
              cleanedItem.remove('work_order_stages');
            }
            
            if (cleanedItem['work_order_items'] != null && 
                cleanedItem['work_order_items'] is List &&
                (cleanedItem['work_order_items'] as List).isNotEmpty &&
                (cleanedItem['work_order_items'] as List).first is! Map) {
              cleanedItem.remove('work_order_items');
            }
            
            if (cleanedItem['work_orders_inventory'] != null && 
                cleanedItem['work_orders_inventory'] is List &&
                (cleanedItem['work_orders_inventory'] as List).isNotEmpty &&
                (cleanedItem['work_orders_inventory'] as List).first is! Map) {
              cleanedItem.remove('work_orders_inventory');
            }
            
            final workOrder = WorkOrder.fromJson(cleanedItem);
            workOrdersList.add(workOrder);
          } catch (e, stackTrace) {
            print("❌ Error parsing work order: $e");
            print("❌ Stack trace: $stackTrace");
            print("❌ Item data: $item");
            // Continue with next item instead of failing completely
          }
        }

        print("✅ Successfully parsed ${workOrdersList.length} work orders");

        allWorkOrders.value = workOrdersList;
        recentWorkOrders.value = workOrdersList.take(5).toList();
        
        // Categorize work orders by status
        pendingWorkOrders.value = workOrdersList.where((wo) => wo.status == 'pending' || wo.status == 'planned').toList();
        inProgressWorkOrders.value = workOrdersList.where((wo) => wo.status == 'in_progress').toList();
        completedWorkOrders.value = workOrdersList.where((wo) => wo.status == 'completed').toList();
        
        print('Loaded ${workOrdersList.length} work orders');
        print('Pending/Planned: ${pendingWorkOrders.length}, In Progress: ${inProgressWorkOrders.length}, Completed: ${completedWorkOrders.length}');
      } else {
        print("❌ API returned error: ${response["message"] ?? "Unknown error"}");
        Get.snackbar(
          "Error",
          response["message"] ?? "Failed to load work orders",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        allWorkOrders.value = [];
        pendingWorkOrders.value = [];
        inProgressWorkOrders.value = [];
        completedWorkOrders.value = [];
      }
    } catch (e, stackTrace) {
      print("❌ Exception in fetchWorkOrders: $e");
      print("❌ Stack trace: $stackTrace");
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      allWorkOrders.value = [];
      pendingWorkOrders.value = [];
      inProgressWorkOrders.value = [];
      completedWorkOrders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get work orders based on selected tab
  List<WorkOrder> get currentWorkOrders {
    switch (selectedTabIndex.value) {
      case 0:
        return allWorkOrders;
      case 1:
        return pendingWorkOrders;
      case 2:
        return inProgressWorkOrders;
      case 3:
        return completedWorkOrders;
      default:
        return allWorkOrders;
    }
  }

  /// Update selected tab
  void updateSelectedTab(int index) {
    selectedTabIndex.value = index;
  }


  void viewOrder(WorkOrder order) {
    // Validate work order ID before navigating
    if (order.id.isEmpty || order.id.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "Invalid work order ID. Cannot view work order details.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return;
    }
    
    // Navigate to work order view
    print("🔍 Navigating to work order: ${order.id} - ${order.title}");
    Get.to(() => WorkOrderView(workOrderId: order.id));
  }

  void editOrder(WorkOrder order) {
    Get.snackbar("Edit Order", "Editing ${order.title}");
  }
}
