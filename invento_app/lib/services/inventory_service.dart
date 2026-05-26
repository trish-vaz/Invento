import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../models/warehouse_model.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class InventoryService {
  InventoryService({AuthService? authService, FirebaseFirestore? firestore})
    : _authService = authService ?? AuthService(),
      _firestore = firestore ?? FirebaseService.firestore;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  String get _userId {
    final user = _authService.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to manage inventory.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _productsCollection {
    return _firestore.collection('users').doc(_userId).collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _batchesCollection {
    return _firestore.collection('users').doc(_userId).collection('batches');
  }

  CollectionReference<Map<String, dynamic>> get _warehousesCollection {
    return _firestore.collection('users').doc(_userId).collection('warehouses');
  }

  Stream<List<ProductModel>> watchProducts() {
    return _productsCollection
        .orderBy('nameLower')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<InventoryBatchModel>> watchBatches() {
    return _batchesCollection
        .orderBy('effectiveExpiryDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryBatchModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<WarehouseModel>> watchWarehouses() {
    return _warehousesCollection
        .orderBy('nameLower')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WarehouseModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<InventoryBatchModel>> watchExpiringBatches({
    int withinDays = 14,
  }) {
    return watchBatches().map(
      (batches) =>
          batches.where((batch) => batch.isExpiringSoon(withinDays)).toList(),
    );
  }

  Future<ProductModel> saveProduct(ProductModel product) async {
    final doc = product.id.isEmpty
        ? _productsCollection.doc()
        : _productsCollection.doc(product.id);
    final now = DateTime.now();
    final savedProduct = product.copyWith(
      id: doc.id,
      createdAt: product.id.isEmpty ? now : product.createdAt,
      updatedAt: now,
    );

    await doc.set(savedProduct.toMap(), SetOptions(merge: true));
    return savedProduct;
  }

  Future<WarehouseModel?> saveWarehouse(WarehouseModel warehouse) async {
    if (warehouse.name.trim().isEmpty) {
      return null;
    }

    final documentId = warehouse.id.isEmpty
        ? warehouse.nameLower.replaceAll(' ', '-')
        : warehouse.id;
    final now = DateTime.now();
    final savedWarehouse = WarehouseModel(
      id: documentId,
      name: warehouse.name.trim(),
      locationCode: warehouse.locationCode.trim(),
      createdAt: warehouse.id.isEmpty ? now : warehouse.createdAt,
      updatedAt: now,
    );

    await _warehousesCollection
        .doc(documentId)
        .set(savedWarehouse.toMap(), SetOptions(merge: true));
    return savedWarehouse;
  }

  Future<InventoryBatchModel> saveBatch(InventoryBatchModel batch) async {
    final doc = batch.id.isEmpty
        ? _batchesCollection.doc()
        : _batchesCollection.doc(batch.id);
    final savedBatch = batch.copyWith(id: doc.id);

    await doc.set(savedBatch.toMap(), SetOptions(merge: true));
    return savedBatch;
  }

  Future<void> deleteBatch(String batchId) {
    return _batchesCollection.doc(batchId).delete();
  }
}
