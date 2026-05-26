import 'package:flutter_test/flutter_test.dart';
import 'package:invento_app/services/scan_payload_parser.dart';

void main() {
  test('parses JSON code payloads into structured scan data', () {
    final payload = ScanPayloadParser.parse(
      '{"name":"Milk","sku":"MILK-001","barcode":"8901234567890","batchNumber":"B-42","quantity":"12","expiryDate":"2026-06-10","warehouse":"Cold Room","location":"A1","position":"front"}',
    );

    expect(payload.productName, 'Milk');
    expect(payload.sku, 'MILK-001');
    expect(payload.scannableCode, '8901234567890');
    expect(payload.batchNumber, 'B-42');
    expect(payload.quantity, 12);
    expect(payload.expiryDate, DateTime(2026, 6, 10));
    expect(payload.warehouseName, 'Cold Room');
    expect(payload.locationCode, 'A1');
    expect(payload.locationPosition, 'front');
    expect(payload.hasStructuredData, isTrue);
  });

  test('parses key value code payloads into structured scan data', () {
    final payload = ScanPayloadParser.parse(
      'product: Yogurt\nbatch: LOT-9\nqty: 8\nmfg: 26/05/2026\nexpiry: 10/06/2026\nlocation: A1\nposition: back',
    );

    expect(payload.productName, 'Yogurt');
    expect(payload.batchNumber, 'LOT-9');
    expect(payload.quantity, 8);
    expect(payload.manufacturedAt, DateTime(2026, 5, 26));
    expect(payload.expiryDate, DateTime(2026, 6, 10));
    expect(payload.locationCode, 'A1');
    expect(payload.locationPosition, 'back');
    expect(payload.hasStructuredData, isTrue);
  });

  test('falls back to raw code value when payload is plain text', () {
    final payload = ScanPayloadParser.parse('ZEPP-RAW-QR-001');

    expect(payload.scannableCode, 'ZEPP-RAW-QR-001');
    expect(payload.productName, isNull);
    expect(payload.hasStructuredData, isFalse);
  });

  test('extracts useful batch fields from OCR label text', () {
    final payload = ScanPayloadParser.parseLabelText(
      'Amul Milk 1L\nBatch: LOT-9\nMFG 26/05/2026\nBest Before 10/06/2026\nQty 12',
    );

    expect(payload.codeFormat, 'ocr');
    expect(payload.productName, 'Amul Milk 1L');
    expect(payload.batchNumber, 'LOT-9');
    expect(payload.manufacturedAt, DateTime(2026, 5, 26));
    expect(payload.expiryDate, DateTime(2026, 6, 10));
    expect(payload.quantity, 12);
    expect(payload.hasRecognizedText, isTrue);
  });
}
