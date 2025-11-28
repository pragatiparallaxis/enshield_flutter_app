import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/workorder/work_order_viewmodel.dart';
import 'package:enshield_app/models/work_order_model.dart';
import 'package:enshield_app/services/api_service.dart';

class AllocateMaterialsWorkOrderModal extends StatefulWidget {
  final String workOrderId;
  final VoidCallback onSuccess;

  const AllocateMaterialsWorkOrderModal({
    super.key,
    required this.workOrderId,
    required this.onSuccess,
  });

  @override
  State<AllocateMaterialsWorkOrderModal> createState() => _AllocateMaterialsWorkOrderModalState();
}

class CategorySizePair {
  final String categoryId;
  final String categoryName;
  final String sizeId;
  final String sizeName;
  

  CategorySizePair({
    required this.categoryId,
    required this.categoryName,
    required this.sizeId,
    required this.sizeName,
  });
}

class ItemQuantity {
  final String categoryId;
  final String categoryName;
  final String sizeId;
  final String sizeName;
  int quantity;

  ItemQuantity({
    required this.categoryId,
    required this.categoryName,
    required this.sizeId,
    required this.sizeName,
    required this.quantity,
  });
}

class _AllocateMaterialsWorkOrderModalState extends State<AllocateMaterialsWorkOrderModal> {
  final _formKey = GlobalKey<FormState>();
  bool _showConfirmation = false;
  List<TextEditingController> _controllers = [];

  String? _selectedFabric;
  String? _selectedColor;
  String? _selectedInventoryId;
  String? _selectedInventoryKey; // Store fabric|color key for items with duplicate IDs
  final _colorController = TextEditingController();
  final _fabricController = TextEditingController();
  final _fabricTypeController = TextEditingController();
  final _totalMetersController = TextEditingController();
  final _tableLengthController = TextEditingController();
  final _layersUsedController = TextEditingController();
  final _pairsPerLayerController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<InventoryItem> _inventoryItems = [];
  List<WorkOrderCategory> _categories = [];
  List<Size> _sizes = [];
  double _defaultTableLength = 11.2;
  
  final List<CategorySizePair> _categorySizePairs = [];
  String? _newCategoryId;
  String? _newSizeId;
  
  List<ItemQuantity> _itemQuantities = [];
  double _calculatedLayers = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Create category/size dialogs
  bool _showCreateCategoryDialog = false;
  bool _showCreateSizeDialog = false;
  final _newCategoryNameController = TextEditingController();
  final _newSizeNameController = TextEditingController();
  bool _isCreatingCategory = false;
  bool _isCreatingSize = false;

  @override
  void initState() {
    super.initState();
    _tableLengthController.text = "11.2";
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load default table length
      try {
        final settingsResponse = await ApiService.getSystemSettings(key: 'default_table_length');
        if (settingsResponse["success"] == true && settingsResponse["data"] != null) {
          final value = settingsResponse["data"]["value"];
          if (value != null) {
            _defaultTableLength = double.tryParse(value.toString()) ?? 11.2;
            _tableLengthController.text = _defaultTableLength.toString();
          }
        }
      } catch (e) {
        // Use default 11.2 if settings not available
        _tableLengthController.text = '11.2';
      }

      // Load inventory items
      final invResponse = await ApiService.getInventoryItems();
      if (invResponse["success"] == true && invResponse["data"] != null) {
        _inventoryItems = (invResponse["data"] as List)
            .map((item) => InventoryItem.fromJson(item))
            .toList();
      }
      
      // Load categories
      final catResponse = await ApiService.getCategories();
      if (catResponse["success"] == true && catResponse["data"] != null) {
        print("🔍 Categories received from backend: ${catResponse["data"]}");
        _categories = (catResponse["data"] as List)
            .map((item) => WorkOrderCategory.fromJson(item))
            .toList();
        print("✅ Parsed ${_categories.length} categories:");
        for (var cat in _categories) {
          print("  - ID: ${cat.id}, Name: ${cat.name}, Active: ${cat.is_active}");
        }
      }
      
      // Load sizes
      final sizeResponse = await ApiService.getSizes();
      if (sizeResponse["success"] == true && sizeResponse["data"] != null) {
        print("🔍 Sizes received from backend: ${sizeResponse["data"]}");
        _sizes = (sizeResponse["data"] as List)
            .map((item) => Size.fromJson(item))
            .toList();
        print("✅ Parsed ${_sizes.length} sizes:");
        for (var size in _sizes) {
          print("  - ID: ${size.id}, Name: ${size.name}, Active: ${size.is_active}");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get unique fabrics from inventory
  List<String> get _uniqueFabrics {
    final fabrics = _inventoryItems
        .where((item) => item.fabric != null && item.fabric!.isNotEmpty)
        .map((item) => item.fabric!)
        .toSet()
        .toList();
    fabrics.sort();
    return fabrics;
  }

  // Get colors for selected fabric
  List<InventoryItem> get _colorsForSelectedFabric {
    if (_selectedFabric == null) return [];
    return _inventoryItems
        .where((item) => item.fabric == _selectedFabric && item.color != null && item.color!.isNotEmpty)
        .toList();
  }

  // Handle fabric selection
  void _handleFabricSelection(String? fabric) {
    setState(() {
      _selectedFabric = fabric;
      _selectedColor = null;
      _selectedInventoryId = null;
      _selectedInventoryKey = null; // Clear the key when fabric changes
      _colorController.clear();
      _fabricController.clear();
      
      // Auto-populate fabric field
      if (fabric != null && fabric.isNotEmpty) {
        _fabricController.text = fabric;
        
        // Auto-select first available color/inventory for this fabric
        // Wait for the state to update before accessing _colorsForSelectedFabric
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
        final availableColors = _colorsForSelectedFabric;
        if (availableColors.isNotEmpty) {
          final firstItem = availableColors.first;
          _selectedColor = firstItem.color;
              _selectedInventoryId = firstItem.id; // ID is already a string (UUID)
              // Store the unique key for items with duplicate IDs
              final fabric = firstItem.fabric ?? '';
              final color = firstItem.color ?? 'Unknown';
              _selectedInventoryKey = '$fabric|$color';
          _colorController.text = firstItem.color ?? '';
        }
          });
        });
      }
    });
  }

  // Handle color/inventory selection
  void _handleColorSelection(InventoryItem? item) {
    if (item == null) {
      setState(() {
        _selectedColor = null;
        _selectedInventoryId = null;
        _selectedInventoryKey = null;
        _colorController.clear();
        _fabricController.clear();
      });
      return;
    }

    setState(() {
      _selectedColor = item.color;
      _selectedInventoryId = item.id; // ID is already a string (UUID)
      // Store the unique key for items with duplicate IDs
      final fabric = item.fabric ?? '';
      final color = item.color ?? 'Unknown';
      _selectedInventoryKey = '$fabric|$color';
      _colorController.text = item.color ?? '';
      _fabricController.text = item.fabric ?? '';
      
      // Auto-populate fabric selection if not already set
      if (_selectedFabric == null && item.fabric != null && item.fabric!.isNotEmpty) {
        _selectedFabric = item.fabric;
      }
    });
  }

  String? _getValidDropdownValue() {
    // If we have a stored key, use it directly (this handles duplicate IDs)
    if (_selectedInventoryKey != null && _selectedInventoryKey!.isNotEmpty) {
      // Verify the key still exists in the current items
      final items = _getUniqueColorDropdownItems();
      if (items.any((item) => item.value == _selectedInventoryKey)) {
        return _selectedInventoryKey;
      }
    }
    
    // Fallback: try to find by ID and create key
    if (_selectedInventoryId == null || _selectedInventoryId!.isEmpty) return null;
    if (_colorsForSelectedFabric.isEmpty) return null;
    
    // Find the item by ID and create the unique key
    InventoryItem? selectedItem;
    try {
      selectedItem = _colorsForSelectedFabric.firstWhere(
        (item) => item.id == _selectedInventoryId,
      );
    } catch (e) {
    return null;
    }
    
    if (selectedItem == null) return null;
    
    // Return the unique key (fabric|color) instead of ID
    final fabric = selectedItem.fabric ?? '';
    final color = selectedItem.color ?? 'Unknown';
    final key = '$fabric|$color';
    
    // Store the key for future use
    _selectedInventoryKey = key;
    
    return key;
  }

  List<DropdownMenuItem<String>> _getUniqueColorDropdownItems() {
    if (_colorsForSelectedFabric.isEmpty) return [];
    
    // Create unique values using fabric+color combination since IDs might be duplicated
    // Use format: "fabric|color" as the value, but store the actual item for lookup
    final items = <DropdownMenuItem<String>>[];
    final seenKeys = <String>{};
    
    for (final item in _colorsForSelectedFabric) {
      final fabric = item.fabric ?? '';
      final color = item.color ?? 'Unknown';
      // Create unique key from fabric and color
      final uniqueKey = '$fabric|$color';
      
      // Only add if we haven't seen this fabric+color combination
      if (!seenKeys.contains(uniqueKey)) {
        seenKeys.add(uniqueKey);
        items.add(
          DropdownMenuItem<String>(
            value: uniqueKey,
        child: Text(
              '$color (${item.available} available)',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
            ),
        ),
      );
      }
    }
    
    return items;
  }

  @override
  void dispose() {
    _colorController.dispose();
    _fabricController.dispose();
    _fabricTypeController.dispose();
    _totalMetersController.dispose();
    _tableLengthController.dispose();
    _layersUsedController.dispose();
    _pairsPerLayerController.dispose();
    _notesController.dispose();
    _newCategoryNameController.dispose();
    _newSizeNameController.dispose();
    super.dispose();
  }

void _calculateLayers() {
  final totalMeters = double.tryParse(_totalMetersController.text);
  final tableLength = double.tryParse(_tableLengthController.text);

  if (totalMeters != null && tableLength != null && tableLength > 0) {
    final layers = totalMeters / tableLength;

    setState(() {
      _calculatedLayers = layers;

      // 👉 Auto-fill Layers Used
      _layersUsedController.text = layers.toStringAsFixed(0);
    });

    // Update quantities because layers changed
    _calculateItemQuantities();
  }
}


  void _handleCategorySelection(String? value) {
    if (value == '__add_category__') {
      setState(() {
        _showCreateCategoryDialog = true;
        _newCategoryId = null;
      });
    } else {
      setState(() {
        _newCategoryId = value;
      });
    }
  }

  void _handleSizeSelection(String? value) {
    if (value == '__add_size__') {
      setState(() {
        _showCreateSizeDialog = true;
        _newSizeId = null;
      });
    } else {
      setState(() {
        _newSizeId = value;
      });
    }
  }

  // Get valid category dropdown value
  String? _getValidCategoryValue() {
    if (_newCategoryId == null || _newCategoryId!.isEmpty) return null;
    // Verify the value exists in the dropdown items
    final items = _getCategoryDropdownItems();
    if (items.any((item) => item.value == _newCategoryId)) {
      return _newCategoryId;
    }
    return null;
  }

  // Get category dropdown items with unique values
  List<DropdownMenuItem<String>> _getCategoryDropdownItems() {
    print("🔍 Building category dropdown items from ${_categories.length} categories");
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '__add_category__',
        child: Text('+ Add Category', style: TextStyle(color: Colors.orange), overflow: TextOverflow.ellipsis),
      ),
    ];
    
    // Use a Set to track seen IDs to prevent duplicates
    final seenIds = <String>{};
    for (final cat in _categories) {
      final idStr = cat.id; // ID is already a string (UUID)
      print("  - Processing category: ID=$idStr, Name=${cat.name}, Already seen: ${seenIds.contains(idStr)}");
      if (!seenIds.contains(idStr)) {
        seenIds.add(idStr);
        items.add(
          DropdownMenuItem<String>(
            value: idStr,
            child: Text(cat.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
        );
      } else {
        print("  ⚠️ Skipping duplicate category ID: $idStr");
      }
    }
    
    print("✅ Created ${items.length} category dropdown items (including +Add option)");
    return items;
  }

  // Get valid size dropdown value
  String? _getValidSizeValue() {
    if (_newSizeId == null || _newSizeId!.isEmpty) return null;
    // Verify the value exists in the dropdown items
    final items = _getSizeDropdownItems();
    if (items.any((item) => item.value == _newSizeId)) {
      return _newSizeId;
    }
    return null;
  }

  // Get size dropdown items with unique values
  List<DropdownMenuItem<String>> _getSizeDropdownItems() {
    print("🔍 Building size dropdown items from ${_sizes.length} sizes");
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '__add_size__',
        child: Text('+ Add Size', style: TextStyle(color: Colors.orange), overflow: TextOverflow.ellipsis),
      ),
    ];
    
    // Use a Set to track seen IDs to prevent duplicates
    final seenIds = <String>{};
    for (final size in _sizes) {
      final idStr = size.id; // ID is already a string (UUID)
      print("  - Processing size: ID=$idStr, Name=${size.name}, Already seen: ${seenIds.contains(idStr)}");
      if (!seenIds.contains(idStr)) {
        seenIds.add(idStr);
        items.add(
          DropdownMenuItem<String>(
            value: idStr,
            child: Text(size.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
        );
      } else {
        print("  ⚠️ Skipping duplicate size ID: $idStr");
      }
    }
    
    print("✅ Created ${items.length} size dropdown items (including +Add option)");
    return items;
  }

  void _addPair() {
    if (_newCategoryId == null || _newSizeId == null) {
      Get.snackbar("Error", "Please select both category and size",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    // IDs are now strings (UUIDs), so compare directly
    final category = _categories.firstWhere((c) => c.id == _newCategoryId);
    final size = _sizes.firstWhere((s) => s.id == _newSizeId);

    setState(() {
      _categorySizePairs.add(CategorySizePair(
        categoryId: _newCategoryId!,
        categoryName: category.name,
        sizeId: _newSizeId!,
        sizeName: size.name,
      ));
      _newCategoryId = null;
      _newSizeId = null;
    });
  }

  Future<void> _handleCreateCategory() async {
    if (_newCategoryNameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Category name is required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => _isCreatingCategory = true);

    try {
      final controller = Get.find<WorkOrderViewModel>();
      final success = await controller.createCategory(_newCategoryNameController.text.trim());
      
      if (success) {
        setState(() {
          _isCreatingCategory = false;
          _showCreateCategoryDialog = false;
          _newCategoryNameController.clear();
          // Reload categories to get the new one
          _loadData();
        });
      } else {
        setState(() => _isCreatingCategory = false);
      }
    } catch (e) {
      setState(() => _isCreatingCategory = false);
      Get.snackbar("Error", "Failed to create category: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> _handleCreateSize() async {
    if (_newSizeNameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Size name is required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => _isCreatingSize = true);

    try {
      final controller = Get.find<WorkOrderViewModel>();
      final success = await controller.createSize(_newSizeNameController.text.trim());
      
      if (success) {
        setState(() {
          _isCreatingSize = false;
          _showCreateSizeDialog = false;
          _newSizeNameController.clear();
          // Reload sizes to get the new one
          _loadData();
        });
      } else {
        setState(() => _isCreatingSize = false);
      }
    } catch (e) {
      setState(() => _isCreatingSize = false);
      Get.snackbar("Error", "Failed to create size: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  void _removePair(int index) {
    setState(() {
      _categorySizePairs.removeAt(index);
    });
  }

void _calculateItemQuantities() {
  final layersUsed = int.tryParse(_layersUsedController.text) ?? 0;
  final pairsPerLayer = int.tryParse(_pairsPerLayerController.text) ?? 0;
  final count = _categorySizePairs.length;

  if (layersUsed <= 0 || pairsPerLayer <= 0 || count == 0) {
    setState(() {
      _itemQuantities = _categorySizePairs.map((pair) {
        return ItemQuantity(
          categoryId: pair.categoryId,
          categoryName: pair.categoryName,
          sizeId: pair.sizeId,
          sizeName: pair.sizeName,
          quantity: 0,
        );
      }).toList();
      _controllers = List.generate(
        _itemQuantities.length,
        (i) => TextEditingController(text: "0"),
      );
    });
    return;
  }

  final totalPieces = layersUsed * pairsPerLayer * 2;

  final baseQty = totalPieces ~/ count;
  int remaining = totalPieces % count;

  _itemQuantities = _categorySizePairs.map((pair) {
    final qty = baseQty + (remaining > 0 ? 1 : 0);
    if (remaining > 0) remaining--;

    return ItemQuantity(
      categoryId: pair.categoryId,
      categoryName: pair.categoryName,
      sizeId: pair.sizeId,
      sizeName: pair.sizeName,
      quantity: qty,
    );
  }).toList();

  // FIX: Update controllers here
  _controllers = List.generate(
    _itemQuantities.length,
    (i) => TextEditingController(
      text: _itemQuantities[i].quantity.toString(),
    ),
  );

  setState(() {});
}

  void _handleQuantityChange(int index, int newQuantity) {
    setState(() {
      _itemQuantities[index].quantity = newQuantity.clamp(0, double.infinity).toInt();
    });
  }

void _handleFormSubmit() {
  if (_formKey.currentState!.validate()) {

    if (_selectedFabric == null || _selectedInventoryId == null) {
      Get.snackbar("Error", "Please select fabric and color",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    if (_categorySizePairs.isEmpty) {
      Get.snackbar("Error", "Please add at least one category-size pair",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    _calculateItemQuantities();

    // 👉 Direct submit – NO confirmation screen
    _handleConfirmAllocation();
  }
}


  Future<void> _handleConfirmAllocation() async {
    if (_itemQuantities.any((item) => item.quantity <= 0)) {
      Get.snackbar("Error", "All quantities must be greater than 0",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    // Validate inventory availability
    if (_selectedInventoryId != null) {
      final selectedItem = _inventoryItems.firstWhere(
        (item) => item.id == _selectedInventoryId,
        orElse: () => _inventoryItems.first,
      );
      final totalMeters = double.tryParse(_totalMetersController.text) ?? 0;
      
      if (selectedItem.available < totalMeters) {
        Get.snackbar(
          "Insufficient Inventory",
          "Available: ${selectedItem.available}, Requested: $totalMeters",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final itemQuantities = _itemQuantities.map((item) => {
        'category_id': item.categoryId,
        'size_id': item.sizeId,
        'quantity': item.quantity,
      }).toList();

      final body = {
        'inventory_id': _selectedInventoryId,
        'color': _colorController.text.trim(),
        'total_meters': double.parse(_totalMetersController.text),
        'table_length': double.parse(_tableLengthController.text),
        'layers_used': int.parse(_layersUsedController.text),
        'item_quantities': itemQuantities,
        if (_pairsPerLayerController.text.isNotEmpty)
          'pairs_per_layer': int.parse(_pairsPerLayerController.text),
        if (_fabricController.text.trim().isNotEmpty)
          'fabric': _fabricController.text.trim(),
        if (_fabricTypeController.text.trim().isNotEmpty)
          'fabric_type': _fabricTypeController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final controller = Get.find<WorkOrderViewModel>();
      final success = await controller.allocateMaterials(body);
      
      if (success) {
        // Reload inventory items to reflect updated available quantity
        await _loadData();
        Get.back();
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to allocate materials: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            child: _isLoading
  ? const Center(child: CircularProgressIndicator())
  : _buildFormView(),

          ),
        ),
        // Create Category Dialog
        if (_showCreateCategoryDialog)
          Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxHeight: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Create New Category'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showCreateCategoryDialog = false;
                            _newCategoryNameController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter the name for the new category.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newCategoryNameController,
                          decoration: const InputDecoration(
                            labelText: 'Category Name *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., JACKET, TROUSER',
                          ),
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _handleCreateCategory(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isCreatingCategory
                                ? null
                                : () {
                                    setState(() {
                                      _showCreateCategoryDialog = false;
                                      _newCategoryNameController.clear();
                                    });
                                  },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreatingCategory ||
                                    _newCategoryNameController.text.trim().isEmpty
                                ? null
                                : _handleCreateCategory,
                            child: _isCreatingCategory
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Create Size Dialog
        if (_showCreateSizeDialog)
          Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxHeight: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Create New Size'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showCreateSizeDialog = false;
                            _newSizeNameController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter the name for the new size.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newSizeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Size Name *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 36, 38, 40',
                          ),
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _handleCreateSize(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isCreatingSize
                                ? null
                                : () {
                                    setState(() {
                                      _showCreateSizeDialog = false;
                                      _newSizeNameController.clear();
                                    });
                                  },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreatingSize ||
                                    _newSizeNameController.text.trim().isEmpty
                                ? null
                                : _handleCreateSize,
                            child: _isCreatingSize
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Allocate Materials'),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fabric Selection
                  DropdownButtonFormField<String>(
                    decoration: _fieldDecoration("Fabric *"),
                    value: _selectedFabric,
                    dropdownColor: const Color(0xFF0F111A),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _uniqueFabrics.map((fabric) {
                      return DropdownMenuItem(
                        value: fabric,
                        child: Text(fabric, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _handleFabricSelection,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a fabric';
                      }
                      return null;
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return _uniqueFabrics.map((fabric) {
                        return Text(
                          fabric,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Color Selection (filtered by fabric)
                  DropdownButtonFormField<String>(
                    decoration: _fieldDecoration("Color *"),
                    value: _getValidDropdownValue(),
                    dropdownColor: const Color(0xFF0F111A),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _getUniqueColorDropdownItems(),
                    onChanged: (value) {
                      if (value != null && _colorsForSelectedFabric.isNotEmpty) {
                        // Parse the unique key (fabric|color) to find the matching item
                        final parts = value.split('|');
                        if (parts.length == 2) {
                          final fabric = parts[0];
                          final color = parts[1];
                        final item = _colorsForSelectedFabric.firstWhere(
                            (i) => (i.fabric ?? '') == fabric && (i.color ?? 'Unknown') == color,
                          orElse: () => _colorsForSelectedFabric.first,
                        );
                        _handleColorSelection(item);
                        }
                      }
                    },
                    validator: (value) {
                      if (_selectedFabric == null) {
                        return 'Please select fabric first';
                      }
                      if (value == null || value.isEmpty) {
                        return 'Please select a color';
                      }
                      return null;
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return _colorsForSelectedFabric.map((item) {
                        return Text(
                          '${item.color ?? 'Unknown'} (${item.available} available)',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Fabric (auto-filled, editable)
                 
                 
                  
                  // Total Meters
                  TextFormField(
                    controller: _totalMetersController,
                    decoration: _fieldDecoration("Total Meters *"),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _calculateLayers(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter total meters';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Table Length (default 11.2, editable)
                  TextFormField(
                    controller: _tableLengthController,
                    decoration: _fieldDecoration("Table Length (meters) * (Default: 11.2)"),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _calculateLayers(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter table length';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Calculated Layers
                  if (_calculatedLayers > 0)
                    Text(
                      "Calculated Layers: ${_calculatedLayers.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  
                  // Layers Used
                  TextFormField(
                    controller: _layersUsedController,
                    decoration: _fieldDecoration("Layers Used *"),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _calculateItemQuantities(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter layers used';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Pairs Per Layer
                  TextFormField(
                    controller: _pairsPerLayerController,
                    decoration: _fieldDecoration("Pairs Per Layer *"),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _calculateItemQuantities(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pairs per layer';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category-Size Pairs
  const Text(
  "Category / Size Selection",
  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
),
SizedBox(height: 12),

// Category Dropdown
DropdownButtonFormField<String>(
  decoration: _fieldDecoration("Select Category"),
  value: _newCategoryId,
  dropdownColor: const Color(0xFF0F111A),
  style: const TextStyle(color: Colors.white),
  isExpanded: true,
  items: _getCategoryDropdownItems(),
  onChanged: (value) {
    setState(() {
      _newCategoryId = value;
      // ❌ DO NOT CLEAR OLD SELECTED SIZES
      // _categorySizePairs.clear();  <-- REMOVE THIS
    });
  },
),
SizedBox(height: 16),

// Size Chips Grid (only for selected category)
if (_newCategoryId != null)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Select Sizes",
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 8),

      Wrap(
        spacing: 8,
        runSpacing: 8,

        children: _sizes.map((size) {
          // Has this size been selected previously?
          final isSelected = _categorySizePairs.any(
            (p) => p.categoryId == _newCategoryId && p.sizeId == size.id,
          );

          return FilterChip(
            selected: isSelected,
            label: Text(size.name),
            selectedColor: Colors.orange.withOpacity(0.3),
            checkmarkColor: Colors.orange,
            backgroundColor: const Color(0xFF0F111A),
            labelStyle: TextStyle(
              color: isSelected ? Colors.orange : Colors.white,
            ),
onSelected: (selected) {
  setState(() {
    final cat = _categories.firstWhere((c) => c.id == _newCategoryId);

    if (selected) {
      final newPair = CategorySizePair(
        categoryId: cat.id,
        categoryName: cat.name,
        sizeId: size.id,
        sizeName: size.name,
      );

      _categorySizePairs.add(newPair);

      _itemQuantities.add(
        ItemQuantity(
          categoryId: cat.id,
          categoryName: cat.name,
          sizeId: size.id,
          sizeName: size.name,
          quantity: 0,
        ),
      );
    } else {
      _categorySizePairs.removeWhere(
        (p) => p.categoryId == _newCategoryId && p.sizeId == size.id,
      );
      _itemQuantities.removeWhere(
        (q) => q.categoryId == _newCategoryId && q.sizeId == size.id,
      );
    }

    _calculateItemQuantities();  // 👈 auto-fill here
  });
},


          );
        }).toList(),
      ),
    ],
  ),

SizedBox(height: 20),

// Selected items list
if (_categorySizePairs.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Selected Items",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),

      ..._categorySizePairs.asMap().entries.map((entry) {
        final index = entry.key;
        final pair = entry.value;

        // find quantity for this category+size
        ItemQuantity qtyItem = _itemQuantities.firstWhere(
          (q) =>
              q.categoryId == pair.categoryId &&
              q.sizeId == pair.sizeId,
          orElse: () => ItemQuantity(
            categoryId: pair.categoryId,
            categoryName: pair.categoryName,
            sizeId: pair.sizeId,
            sizeName: pair.sizeName,
            quantity: 0,
          ),
        );

        return Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F111A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${pair.categoryName} - ${pair.sizeName}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(
                width: 90,
                child: TextFormField(
                 controller: _controllers[index],

                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Qty",
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onChanged: (value) {
                    int qty = int.tryParse(value) ?? 0;

                    setState(() {
                      qtyItem.quantity = qty;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }),

      SizedBox(height: 16),

      // Live total
      Text(
        "Total: ${_itemQuantities.fold<int>(0, (sum, item) => sum + item.quantity)} pieces",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),


                  
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: _fieldDecoration("Notes (Optional)"),
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleFormSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                    ),
                    child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF0F111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF6F00)),
      ),
    );
  }
}
