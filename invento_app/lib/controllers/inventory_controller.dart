import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../models/warehouse_model.dart';
import '../services/inventory_service.dart';

class InventoryController {
  InventoryController({InventoryService? inventoryService})
    : _inventoryService = inventoryService ?? InventoryService();

  final InventoryService _inventoryService;

  Stream<List<ProductModel>> watchProducts() {
    return _inventoryService.watchProducts();
  }

  Stream<List<WarehouseModel>> watchWarehouses() {
    return _inventoryService.watchWarehouses();
  }

  Stream<List<InventoryBatchModel>> watchBatches() {
    return _inventoryService.watchBatches();
  }

  Stream<List<InventoryBatchModel>> watchExpiringBatches({
    int withinDays = 14,
  }) {
    return _inventoryService.watchExpiringBatches(withinDays: withinDays);
  }

  Future<void> addInventoryEntry({
    required String batchNumber,
    required int quantity,
    required String warehouseName,
    required String locationCode,
    required String locationPosition,
    required String source,
    DateTime? manufacturedAt,
    DateTime? expiryDate,
    ProductModel? existingProduct,
    String productName = '',
    String sku = '',
    String scannableCode = '',
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (batchNumber.trim().isEmpty) {
      throw ArgumentError('Batch number is required.');
    }

    ProductModel product;
    if (existingProduct != null) {
      product = existingProduct;
    } else {
      if (productName.trim().isEmpty) {
        throw ArgumentError('Product name is required.');
      }

      product = await _inventoryService.saveProduct(
        ProductModel(
          id: '',
          name: productName.trim(),
          sku: sku.trim(),
          qrCode: scannableCode.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    await _inventoryService.saveWarehouse(
      WarehouseModel(
        id: '',
        name: warehouseName.trim(),
        locationCode: locationCode.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await _inventoryService.saveBatch(
      InventoryBatchModel(
        id: '',
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        batchNumber: batchNumber.trim(),
        quantity: quantity,
        remainingQuantity: quantity,
        manufacturedAt: manufacturedAt,
        expiryDate: expiryDate,
        receivedAt: DateTime.now(),
        warehouseName: warehouseName.trim(),
        locationCode: locationCode.trim(),
        locationPosition: locationPosition.trim().isEmpty
            ? 'unspecified'
            : locationPosition.trim(),
        source: source,
        status: 'active',
      ),
    );
  }

  Future<void> deleteBatch(String batchId) {
    return _inventoryService.deleteBatch(batchId);
  }
}
