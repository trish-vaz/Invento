import '../core/utils/helpers.dart';
import 'inventory_model.dart';

class LocationProductGuidance {
  const LocationProductGuidance({
    required this.productId,
    required this.productName,
    required this.batches,
  });

  final String productId;
  final String productName;
  final List<InventoryBatchModel> batches;

  List<InventoryBatchModel> get activeBatches {
    final filtered =
        batches
            .where((batch) => batch.remainingQuantity > 0 && !batch.isExpired)
            .toList()
          ..sort(_compareBatchesForPick);
    return filtered;
  }

  List<InventoryBatchModel> get sortedBatches {
    final sorted = List<InventoryBatchModel>.from(batches)
      ..sort(_compareBatchesForPick);
    return sorted;
  }

  InventoryBatchModel? get nextPick {
    if (activeBatches.isEmpty) {
      return null;
    }

    return activeBatches.first;
  }

  bool get needsRotation {
    final pick = nextPick;
    return pick != null &&
        activeBatches.length > 1 &&
        pick.locationPosition != 'front';
  }
}

class LocationInventoryGroup {
  const LocationInventoryGroup({
    required this.warehouseName,
    required this.locationCode,
    required this.batches,
  });

  final String warehouseName;
  final String locationCode;
  final List<InventoryBatchModel> batches;

  String get locationLabel {
    if (warehouseName.trim().isEmpty) {
      return locationCode;
    }

    return '$warehouseName / $locationCode';
  }

  List<LocationProductGuidance> get productGuidance {
    final grouped = <String, List<InventoryBatchModel>>{};
    for (final batch in batches) {
      grouped.putIfAbsent(batch.productId, () => []).add(batch);
    }

    final guidance =
        grouped.values
            .map(
              (productBatches) => LocationProductGuidance(
                productId: productBatches.first.productId,
                productName: productBatches.first.productName,
                batches: productBatches,
              ),
            )
            .toList()
          ..sort((a, b) {
            final aPick = a.nextPick;
            final bPick = b.nextPick;
            if (aPick == null && bPick == null) {
              return normalizeKey(
                a.productName,
              ).compareTo(normalizeKey(b.productName));
            }
            if (aPick == null) {
              return 1;
            }
            if (bPick == null) {
              return -1;
            }
            final expiryCompare = aPick.effectiveExpiryDate.compareTo(
              bPick.effectiveExpiryDate,
            );
            if (expiryCompare != 0) {
              return expiryCompare;
            }
            return normalizeKey(
              a.productName,
            ).compareTo(normalizeKey(b.productName));
          });

    return guidance;
  }

  InventoryBatchModel? get nextOverallPick {
    final active =
        productGuidance
            .map((guidance) => guidance.nextPick)
            .whereType<InventoryBatchModel>()
            .toList()
          ..sort(_compareBatchesForPick);

    if (active.isEmpty) {
      return null;
    }

    return active.first;
  }

  bool get hasActiveBatches => nextOverallPick != null;

  int get activeBatchCount {
    return batches
        .where((batch) => batch.remainingQuantity > 0 && !batch.isExpired)
        .length;
  }
}

List<LocationInventoryGroup> buildLocationInventoryGroups(
  List<InventoryBatchModel> batches,
) {
  final grouped = <String, List<InventoryBatchModel>>{};
  for (final batch in batches) {
    final key =
        '${normalizeKey(batch.warehouseName)}::${normalizeKey(batch.locationCode)}';
    grouped.putIfAbsent(key, () => []).add(batch);
  }

  final locations =
      grouped.values
          .map(
            (locationBatches) => LocationInventoryGroup(
              warehouseName: locationBatches.first.warehouseName,
              locationCode: locationBatches.first.locationCode,
              batches: locationBatches,
            ),
          )
          .toList()
        ..sort((a, b) {
          final aPick = a.nextOverallPick;
          final bPick = b.nextOverallPick;
          if (aPick == null && bPick == null) {
            return normalizeKey(
              a.locationLabel,
            ).compareTo(normalizeKey(b.locationLabel));
          }
          if (aPick == null) {
            return 1;
          }
          if (bPick == null) {
            return -1;
          }
          final expiryCompare = aPick.effectiveExpiryDate.compareTo(
            bPick.effectiveExpiryDate,
          );
          if (expiryCompare != 0) {
            return expiryCompare;
          }
          return normalizeKey(
            a.locationLabel,
          ).compareTo(normalizeKey(b.locationLabel));
        });

  return locations;
}

int _compareBatchesForPick(InventoryBatchModel a, InventoryBatchModel b) {
  final expiryCompare = a.effectiveExpiryDate.compareTo(b.effectiveExpiryDate);
  if (expiryCompare != 0) {
    return expiryCompare;
  }

  final positionCompare = a.locationPositionRank.compareTo(
    b.locationPositionRank,
  );
  if (positionCompare != 0) {
    return positionCompare;
  }

  return a.receivedAt.compareTo(b.receivedAt);
}
