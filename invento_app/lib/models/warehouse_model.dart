import '../core/utils/date_utils.dart';
import '../core/utils/helpers.dart';

class WarehouseModel {
  const WarehouseModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.locationCode = '',
  });

  final String id;
  final String name;
  final String locationCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get nameLower => normalizeKey(name);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'locationCode': locationCode,
      'createdAt': toTimestamp(createdAt),
      'updatedAt': toTimestamp(updatedAt),
    };
  }

  factory WarehouseModel.fromMap(String id, Map<String, dynamic> map) {
    return WarehouseModel(
      id: id,
      name: map['name'] as String? ?? '',
      locationCode: map['locationCode'] as String? ?? '',
      createdAt: readDateTime(map['createdAt']),
      updatedAt: readDateTime(map['updatedAt']),
    );
  }
}
