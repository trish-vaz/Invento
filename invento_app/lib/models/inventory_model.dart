import '../core/utils/date_utils.dart';

class InventoryBatchModel {
  const InventoryBatchModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.batchNumber,
    required this.quantity,
    required this.remainingQuantity,
    required this.receivedAt,
    required this.warehouseName,
    required this.locationCode,
    required this.status,
    this.sku = '',
    this.manufacturedAt,
    this.expiryDate,
    this.source = 'manual',
    this.locationPosition = 'unspecified',
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String batchNumber;
  final int quantity;
  final int remainingQuantity;
  final DateTime receivedAt;
  final DateTime? manufacturedAt;
  final DateTime? expiryDate;
  final String warehouseName;
  final String locationCode;
  final String source;
  final String status;
  final String locationPosition;

  DateTime get effectiveExpiryDate {
    return expiryDate ?? DateTime(9999, 12, 31);
  }

  bool get isExpired {
    if (expiryDate == null) {
      return false;
    }

    return expiryDate!.isBefore(DateTime.now());
  }

  bool isExpiringSoon([int withinDays = 14]) {
    final remainingDays = daysUntil(expiryDate);
    if (remainingDays == null) {
      return false;
    }

    return remainingDays >= 0 && remainingDays <= withinDays;
  }

  String get computedStatus {
    if (remainingQuantity <= 0) {
      return 'depleted';
    }

    if (isExpired) {
      return 'expired';
    }

    return status;
  }

  String get locationLabel {
    if (warehouseName.trim().isEmpty) {
      return locationCode;
    }

    return '$warehouseName / $locationCode';
  }

  String get locationPositionLabel {
    switch (locationPosition) {
      case 'front':
        return 'Front';
      case 'middle':
        return 'Middle';
      case 'back':
        return 'Back';
      case 'unspecified':
      default:
        return 'Unspecified';
    }
  }

  int get locationPositionRank {
    switch (locationPosition) {
      case 'front':
        return 0;
      case 'middle':
        return 1;
      case 'back':
        return 2;
      case 'unspecified':
      default:
        return 9;
    }
  }

  InventoryBatchModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? sku,
    String? batchNumber,
    int? quantity,
    int? remainingQuantity,
    DateTime? receivedAt,
    DateTime? manufacturedAt,
    DateTime? expiryDate,
    String? warehouseName,
    String? locationCode,
    String? locationPosition,
    String? source,
    String? status,
  }) {
    return InventoryBatchModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      receivedAt: receivedAt ?? this.receivedAt,
      manufacturedAt: manufacturedAt ?? this.manufacturedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      warehouseName: warehouseName ?? this.warehouseName,
      locationCode: locationCode ?? this.locationCode,
      locationPosition: locationPosition ?? this.locationPosition,
      source: source ?? this.source,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'receivedAt': toTimestamp(receivedAt),
      'manufacturedAt': toTimestamp(manufacturedAt),
      'expiryDate': toTimestamp(expiryDate),
      'effectiveExpiryDate': toTimestamp(effectiveExpiryDate),
      'warehouseName': warehouseName,
      'locationCode': locationCode,
      'locationPosition': locationPosition,
      'source': source,
      'status': status,
    };
  }

  factory InventoryBatchModel.fromMap(String id, Map<String, dynamic> map) {
    return InventoryBatchModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      batchNumber: map['batchNumber'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (map['remainingQuantity'] as num?)?.toInt() ?? 0,
      receivedAt: readDateTime(map['receivedAt']),
      manufacturedAt: map['manufacturedAt'] == null
          ? null
          : readDateTime(map['manufacturedAt']),
      expiryDate: map['expiryDate'] == null
          ? null
          : readDateTime(map['expiryDate']),
      warehouseName: map['warehouseName'] as String? ?? '',
      locationCode: map['locationCode'] as String? ?? '',
      locationPosition: map['locationPosition'] as String? ?? 'unspecified',
      source: map['source'] as String? ?? 'manual',
      status: map['status'] as String? ?? 'active',
    );
  }
}
