import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/scan_payload_model.dart';
import 'scan_payload_parser.dart';

class ScannerService {
  const ScannerService._();

  static ScanPayloadModel fromBarcode(Barcode barcode) {
    final rawValue = barcode.rawValue?.trim() ?? '';
    return ScanPayloadParser.parse(
      rawValue,
      codeFormat: barcode.format.name,
    ).copyWith(
      scannableCode: rawValue.isEmpty ? null : rawValue,
      codeFormat: barcode.format.name,
    );
  }
}
