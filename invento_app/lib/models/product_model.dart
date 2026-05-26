import '../core/utils/date_utils.dart';
import '../core/utils/helpers.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.sku = '',
    this.qrCode = '',
    this.unit = 'units',
  });

  final String id;
  final String name;
  final String sku;
  final String qrCode;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get nameLower => normalizeKey(name);

  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? qrCode,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      qrCode: qrCode ?? this.qrCode,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'sku': sku,
      'qrCode': qrCode,
      'unit': unit,
      'createdAt': toTimestamp(createdAt),
      'updatedAt': toTimestamp(updatedAt),
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      qrCode: map['qrCode'] as String? ?? '',
      unit: map['unit'] as String? ?? 'units',
      createdAt: readDateTime(map['createdAt']),
      updatedAt: readDateTime(map['updatedAt']),
    );
  }
}
