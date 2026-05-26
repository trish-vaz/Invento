class ScanPayloadModel {
  const ScanPayloadModel({
    required this.rawValue,
    this.scannableCode,
    this.codeFormat,
    this.productName,
    this.sku,
    this.batchNumber,
    this.quantity,
    this.manufacturedAt,
    this.expiryDate,
    this.warehouseName,
    this.locationCode,
    this.locationPosition,
    this.recognizedText,
  });

  final String rawValue;
  final String? scannableCode;
  final String? codeFormat;
  final String? productName;
  final String? sku;
  final String? batchNumber;
  final int? quantity;
  final DateTime? manufacturedAt;
  final DateTime? expiryDate;
  final String? warehouseName;
  final String? locationCode;
  final String? locationPosition;
  final String? recognizedText;

  ScanPayloadModel copyWith({
    String? rawValue,
    String? scannableCode,
    String? codeFormat,
    String? productName,
    String? sku,
    String? batchNumber,
    int? quantity,
    DateTime? manufacturedAt,
    DateTime? expiryDate,
    String? warehouseName,
    String? locationCode,
    String? locationPosition,
    String? recognizedText,
  }) {
    return ScanPayloadModel(
      rawValue: rawValue ?? this.rawValue,
      scannableCode: scannableCode ?? this.scannableCode,
      codeFormat: codeFormat ?? this.codeFormat,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      manufacturedAt: manufacturedAt ?? this.manufacturedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      warehouseName: warehouseName ?? this.warehouseName,
      locationCode: locationCode ?? this.locationCode,
      locationPosition: locationPosition ?? this.locationPosition,
      recognizedText: recognizedText ?? this.recognizedText,
    );
  }

  bool get hasScannableCode {
    return _hasValue(scannableCode);
  }

  bool get hasRecognizedText {
    return _hasValue(recognizedText);
  }

  bool get hasStructuredData {
    return _hasValue(productName) ||
        _hasValue(sku) ||
        _hasValue(batchNumber) ||
        quantity != null ||
        manufacturedAt != null ||
        expiryDate != null ||
        _hasValue(warehouseName) ||
        _hasValue(locationCode) ||
        _hasValue(locationPosition);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
