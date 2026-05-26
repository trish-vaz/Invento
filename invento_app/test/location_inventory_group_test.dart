import 'package:flutter_test/flutter_test.dart';
import 'package:invento_app/models/inventory_model.dart';
import 'package:invento_app/models/location_inventory_group.dart';

void main() {
  InventoryBatchModel batch({
    required String id,
    required String batchNumber,
    required DateTime expiryDate,
    required String locationPosition,
    String productId = 'milk',
    String productName = 'Milk',
    String locationCode = 'A1',
    String warehouseName = 'Cold Room',
  }) {
    return InventoryBatchModel(
      id: id,
      productId: productId,
      productName: productName,
      batchNumber: batchNumber,
      quantity: 10,
      remainingQuantity: 10,
      receivedAt: DateTime(2026, 5, 26),
      warehouseName: warehouseName,
      locationCode: locationCode,
      locationPosition: locationPosition,
      expiryDate: expiryDate,
      status: 'active',
    );
  }

  test(
    'groups multiple batches in the same location and suggests the earliest expiry first',
    () {
      final groups = buildLocationInventoryGroups([
        batch(
          id: '1',
          batchNumber: 'B-0607',
          expiryDate: DateTime(2026, 6, 7),
          locationPosition: 'back',
        ),
        batch(
          id: '2',
          batchNumber: 'B-0606',
          expiryDate: DateTime(2026, 6, 6),
          locationPosition: 'front',
        ),
      ]);

      expect(groups, hasLength(1));
      expect(groups.first.locationCode, 'A1');
      expect(groups.first.nextOverallPick?.batchNumber, 'B-0606');
      expect(groups.first.productGuidance.first.sortedBatches, hasLength(2));
      expect(groups.first.productGuidance.first.needsRotation, isFalse);
    },
  );

  test('flags rotation when the earliest batch is not at the front', () {
    final groups = buildLocationInventoryGroups([
      batch(
        id: '1',
        batchNumber: 'B-0606',
        expiryDate: DateTime(2026, 6, 6),
        locationPosition: 'back',
      ),
      batch(
        id: '2',
        batchNumber: 'B-0607',
        expiryDate: DateTime(2026, 6, 7),
        locationPosition: 'front',
      ),
    ]);

    final guidance = groups.first.productGuidance.first;
    expect(guidance.nextPick?.batchNumber, 'B-0606');
    expect(guidance.needsRotation, isTrue);
  });
}
