import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:enshield_app/routes.dart';

class ApiService {
  // TODO: Move to .env or config file in the future
  static const String baseUrl = 'http://185.165.240.191:3056';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static final GetStorage _storage = GetStorage();
  static const String _tokenKey = 'auth_token';

  /// Get token from storage
  static String get bearerToken => _storage.read(_tokenKey) ?? '';

  /// Save token in storage
  static void setToken(String? token) {
    if (token == null) {
      _storage.remove(_tokenKey);
    } else {
      _storage.write(_tokenKey, token);
    }
  }

  /// Clear token when logging out
  static void clearToken() {
    _storage.remove(_tokenKey);
  }

  /// Common headers
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (bearerToken.isNotEmpty) 'Authorization': 'Bearer $bearerToken',
    };
  }

  /// Generic GET request
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print("🌐 GET Request: $url");
    
    try {
      final response = await http.get(url, headers: getHeaders())
          .timeout(timeoutDuration);
      
      print("📡 Response Status: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("❌ GET Error: $e");
      throw Exception('Network error: $e');
    }
  }

  /// Generic POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: getHeaders(),
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      print("❌ POST Error: $e");
      throw Exception('Network error: $e');
    }
  }

  /// Generic PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print("🌐 PUT Request: $url");
    
    try {
      final response = await http.put(
        url,
        headers: getHeaders(),
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      print("📥 PUT Response: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("❌ PUT Error: $e");
      throw Exception('Network error: $e');
    }
  }

  /// Generic DELETE request
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.delete(url, headers: getHeaders())
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      print("❌ DELETE Error: $e");
      throw Exception('Network error: $e');
    }
  }

  /// Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // If response is not JSON (e.g. empty 200 OK), return empty map or success
        return {'success': true};
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Authentication error - clear token and redirect to login
      clearToken();
      Get.offAllNamed(Routes.signin);
      throw Exception('Authentication failed. Please login again.');
    } else {
      // For other errors, try to parse the response body
      try {
        final errorBody = jsonDecode(response.body);
        return errorBody;
      } catch (e) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }

  // ===== PRODUCTION API ENDPOINTS =====

  /// Get all work orders
  static Future<dynamic> getWorkOrders() async {
    try {
      final response = await get('/api/production/work-orders');
      
      // Ensure response has the expected structure
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          return response;
        } else {
          return {
            'success': false,
            'data': [],
            'message': response['error'] ?? response['message'] ?? 'Failed to fetch work orders'
          };
        }
      }
      
      return {
        'success': false,
        'data': [],
        'message': 'Invalid response format'
      };
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': e.toString()
      };
    }
  }

  /// Get work order by ID
  static Future<dynamic> getWorkOrder(String id) async {
    return await get('/api/production/work-orders/$id');
  }

  /// Get work order details with items, stages, and inventory
  static Future<dynamic> getWorkOrderDetails(String id) async {
    return await get('/api/production/work-orders/$id/details');
  }

  /// Create work order
  static Future<dynamic> createWorkOrder(Map<String, dynamic> body) async {
    return await post('/api/production/work-orders', body);
  }

  /// Get all batches
  static Future<dynamic> getBatches() async {
    return await get('/api/production/batches');
  }

  /// Get batches by work order ID
  static Future<dynamic> getBatchesByWorkOrder(String workOrderId) async {
    return await get('/api/production/batches?work_order_id=$workOrderId');
  }

  /// Get batch by ID
  static Future<dynamic> getBatch(String id) async {
    return await get('/api/production/batches/$id');
  }

  /// Create batch
  static Future<dynamic> createBatch(Map<String, dynamic> body) async {
    return await post('/api/production/batches', body);
  }

  /// Start batch processing
  static Future<dynamic> startBatch(String id) async {
    return await post('/api/production/batches/$id/start', {});
  }

  /// Move batch to next stage
  static Future<dynamic> moveBatchToNextStage(String id, Map<String, dynamic> body) async {
    return await post('/api/production/batches/$id/move-to-next-stage', body);
  }

  /// Get batch stage progress
  static Future<dynamic> getBatchStageProgress(String batchId) async {
    return await get('/api/production/batch-stage-progress?batch_id=$batchId');
  }

  /// Update stage progress
  static Future<dynamic> updateStageProgress(String id, Map<String, dynamic> body) async {
    return await put('/api/production/batch-stage-progress/$id', body);
  }

  /// Get product pieces
  static Future<dynamic> getProductPieces(String batchId) async {
    return await get('/api/production/product-pieces?batch_id=$batchId');
  }

  /// Get outsourced parties
  static Future<dynamic> getOutsourcedParties() async {
    return await get('/api/production/outsourced-parties');
  }

  /// Create outsourced party
  static Future<dynamic> createOutsourcedParty(Map<String, dynamic> body) async {
    return await post('/api/production/outsourced-parties', body);
  }

  /// Update outsourced party
  static Future<dynamic> updateOutsourcedParty(String id, Map<String, dynamic> body) async {
    return await put('/api/production/outsourced-parties/$id', body);
  }

  /// Delete outsourced party
  static Future<dynamic> deleteOutsourcedParty(String id) async {
    return await delete('/api/production/outsourced-parties/$id');
  }

  /// Get app users
  static Future<dynamic> getAppUsers() async {
    return await get('/api/app-users');
  }

  /// Get products
  static Future<dynamic> getProducts() async {
    return await get('/api/products');
  }

  /// Get product by ID
  static Future<dynamic> getProduct(String id) async {
    return await get('/api/products/$id');
  }

  /// Create product
  static Future<dynamic> createProduct(Map<String, dynamic> body) async {
    return await post('/api/products', body);
  }

  /// Get production stats
  static Future<dynamic> getProductionStats() async {
    return await get('/api/production/stats');
  }

  /// Get production stages
  static Future<dynamic> getProductionStages() async {
    return await get('/api/production/stages');
  }

  /// Get product pieces by batch ID
  static Future<dynamic> getProductPiecesByBatch(String batchId) async {
    return await get('/api/production/product-pieces?batch_id=$batchId');
  }

  /// Get batch stage progress by batch ID
  static Future<dynamic> getBatchStageProgressByBatch(String batchId) async {
    return await get('/api/production/batch-stage-progress?batch_id=$batchId');
  }

  /// Start batch processing
  static Future<dynamic> startBatchProcessing(String batchId) async {
    return await post('/api/production/batches/$batchId/start', {});
  }

  /// Start stage
  static Future<dynamic> startStage(String batchId, String stageId) async {
    return await post('/api/production/batches/$batchId/start-stage', {'stageId': stageId});
  }

  /// Update work order status
  static Future<dynamic> updateWorkOrderStatus(String workOrderId, String status) async {
    return await put('/api/work-orders/$workOrderId/status', {'status': status});
  }

  /// Get work orders by status
  static Future<dynamic> getWorkOrdersByStatus(String status) async {
    return await get('/api/work-orders?status=$status');
  }

  /// Allocate materials to work order
  static Future<dynamic> allocateMaterials(String workOrderId, Map<String, dynamic> body) async {
    return await post('/api/production/work-orders/$workOrderId/allocate-materials', body);
  }

  /// Complete stage for work order item
  static Future<dynamic> completeStage(String workOrderId, Map<String, dynamic> body) async {
    return await post('/api/production/work-orders/$workOrderId/complete-stage', body);
  }

  /// Get categories
  static Future<dynamic> getCategories() async {
    return await get('/api/production/categories');
  }

  /// Create category
  static Future<dynamic> createCategory(Map<String, dynamic> body) async {
    return await post('/api/production/categories', body);
  }

  /// Get sizes
  static Future<dynamic> getSizes() async {
    return await get('/api/production/sizes');
  }

  /// Create size
  static Future<dynamic> createSize(Map<String, dynamic> body) async {
    return await post('/api/production/sizes', body);
  }

  /// Get workers
  static Future<dynamic> getWorkers() async {
    try {
      final response = await get('/api/production/workers');
      
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          return response;
        } else {
          return {
            'success': false,
            'data': [],
            'message': response['error'] ?? response['message'] ?? 'Failed to fetch workers'
          };
        }
      }
      
      return {
        'success': false,
        'data': [],
        'message': 'Invalid response format'
      };
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': e.toString()
      };
    }
  }

  /// Create worker
  static Future<dynamic> createWorker(Map<String, dynamic> body) async {
    return await post('/api/production/workers', body);
  }

  /// Get worker by ID
  static Future<dynamic> getWorker(String id) async {
    return await get('/api/production/workers/$id');
  }

  /// Update worker
  static Future<dynamic> updateWorker(String id, Map<String, dynamic> body) async {
    return await put('/api/production/workers/$id', body);
  }

  /// Get inventory items (for production/work orders)
  static Future<dynamic> getInventoryItems() async {
    return await get('/api/production/inventory');
  }

  /// Get inventory items (for inventory management - uses main inventory endpoint)
  static Future<dynamic> getInventoryItemsForManagement() async {
    return await get('/api/inventory');
  }

  /// Get system settings
  static Future<dynamic> getSystemSettings({String? key}) async {
    final query = key != null ? '?key=$key' : '';
    return await get('/api/production/settings$query');
  }

  /// Assign workers to stage
  static Future<dynamic> assignWorkersToStage(String workOrderId, String stageId, Map<String, dynamic> body) async {
    return await post('/api/production/work-orders/$workOrderId/stages/$stageId/assign-workers', body);
  }

  /// Get stage worker assignments
  static Future<dynamic> getStageWorkerAssignments(String workOrderId, String stageId) async {
    return await get('/api/production/work-orders/$workOrderId/stages/$stageId/assign-workers');
  }

  /// Get worker assignments
  static Future<dynamic> getWorkerAssignments(String workerId, {String? status}) async {
    final query = status != null ? '?status=$status' : '';
    return await get('/api/production/workers/$workerId/assignments$query');
  }

  /// Submit worker assignment
  static Future<dynamic> submitWorkerAssignment(String assignmentId, Map<String, dynamic> body) async {
    return await put('/api/production/assignments/$assignmentId/submit', body);
  }

  /// Approve worker assignment
  static Future<dynamic> approveWorkerAssignment(String assignmentId, Map<String, dynamic> body) async {
    return await put('/api/production/assignments/$assignmentId/approve', body);
  }

  /// Get stage submissions
  static Future<dynamic> getStageSubmissions(String workOrderId, String stageId, {String? stageName, String? workOrderItemId}) async {
    String endpoint = '/api/production/work-orders/$workOrderId/stages/$stageId/submissions';
    
    // Add query parameters if stage ID is invalid and we have stage name and item ID
    if ((stageId == '0' || stageId == 'new' || stageId.isEmpty) && stageName != null && workOrderItemId != null) {
      endpoint += '?stage_name=$stageName&work_order_item_id=$workOrderItemId';
    }
    
    return await get(endpoint);
  }

  /// Finalize stage
  static Future<dynamic> finalizeStage(String workOrderId, String stageId) async {
    return await put('/api/production/work-orders/$workOrderId/stages/$stageId/finalize', {});
  }

  /// Get current worker's assignments
  static Future<dynamic> getMyAssignments({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    return await get('/api/production/workers/my-assignments$query');
  }

  /// Add inventory inward (receive/add inventory)
  static Future<dynamic> addInventoryInward(Map<String, dynamic> body) async {
    return await post('/api/inventory/inward', body);
  }

  /// Return layers and recalculate quantities
  static Future<dynamic> returnLayers(String inventoryId, Map<String, dynamic> body) async {
    return await post('/api/production/work-orders/inventory/$inventoryId/return-layers', body);
  }

  /// Update existing material allocation
  static Future<dynamic> updateAllocation(String workOrderId, String inventoryId, Map<String, dynamic> body) async {
    return await put('/api/production/work-orders/$workOrderId/update-allocation/$inventoryId', body);
  }

  /// Allocate inventory to workers for a stage
  static Future<dynamic> allocateInventoryToWorkers(String workOrderId, String stageId, Map<String, dynamic> body) async {
    return await post('/api/production/work-orders/$workOrderId/stages/$stageId/allocate-inventory', body);
  }

  /// Get inventory allocations for a stage
  static Future<dynamic> getStageInventoryAllocations(String workOrderId, String stageId) async {
    return await get('/api/production/work-orders/$workOrderId/stages/$stageId/allocate-inventory');
  }

  /// Worker returns inventory
  static Future<dynamic> returnWorkerInventory(String allocationId, Map<String, dynamic> body) async {
    return await post('/api/production/inventory-allocations/$allocationId/return', body);
  }

  /// Admin approves/rejects inventory return
  static Future<dynamic> approveInventoryReturn(String allocationId, Map<String, dynamic> body) async {
    return await post('/api/production/inventory-allocations/$allocationId/approve', body);
  }
}
