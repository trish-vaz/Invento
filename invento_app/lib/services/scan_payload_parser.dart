import 'dart:convert';

import '../models/scan_payload_model.dart';

class ScanPayloadParser {
  const ScanPayloadParser._();

  static ScanPayloadModel parse(String rawValue, {String? codeFormat}) {
    final trimmed = rawValue.trim();
    final parsedMap = _tryParseJson(trimmed) ?? _tryParseKeyValuePairs(trimmed);

    if (parsedMap == null) {
      return ScanPayloadModel(
        rawValue: trimmed,
        scannableCode: trimmed.isEmpty ? null : trimmed,
        codeFormat: codeFormat,
      );
    }

    return ScanPayloadModel(
      rawValue: trimmed,
      scannableCode: _readString(parsedMap, const [
        'scannableCode',
        'barcodeValue',
        'barcode',
        'upc',
        'ean',
        'ean13',
        'qrCode',
        'qr',
        'code',
      ]),
      codeFormat: codeFormat ?? _readString(parsedMap, const ['codeFormat']),
      productName: _readString(parsedMap, const [
        'productName',
        'product',
        'name',
        'itemName',
      ]),
      sku: _readString(parsedMap, const ['sku', 'productCode', 'itemCode']),
      batchNumber: _readString(parsedMap, const [
        'batchNumber',
        'batch',
        'lot',
        'lotNumber',
      ]),
      quantity: _readInt(parsedMap, const ['quantity', 'qty', 'count']),
      manufacturedAt: _readDate(parsedMap, const [
        'manufacturedAt',
        'manufacturingDate',
        'mfgDate',
        'mfg',
      ]),
      expiryDate: _readDate(parsedMap, const [
        'expiryDate',
        'expirationDate',
        'expiry',
        'exp',
        'bestBefore',
        'useBy',
      ]),
      warehouseName: _readString(parsedMap, const [
        'warehouseName',
        'warehouse',
        'zone',
      ]),
      locationCode: _readString(parsedMap, const [
        'locationCode',
        'location',
        'bin',
        'rack',
      ]),
      locationPosition: _readString(parsedMap, const [
        'locationPosition',
        'position',
        'slot',
        'frontBack',
      ]),
    );
  }

  static ScanPayloadModel parseLabelText(String rawText) {
    final normalizedText = rawText.trim();
    final lines = normalizedText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final structured = parse(normalizedText, codeFormat: 'ocr');
    if (structured.hasStructuredData) {
      return structured.copyWith(
        recognizedText: normalizedText,
        productName: structured.productName ?? _guessProductName(lines),
        sku:
            structured.sku ??
            _extractValue(lines, const [
              'sku',
              'item code',
              'product code',
              'code',
            ]),
        batchNumber:
            structured.batchNumber ??
            _extractValue(lines, const ['batch', 'batch no', 'lot', 'lot no']),
        quantity: structured.quantity ?? _extractQuantity(lines),
        manufacturedAt:
            structured.manufacturedAt ??
            _extractDateByKeywords(lines, const [
              'mfg',
              'mfd',
              'manufactured',
              'packed on',
              'pack date',
            ]),
        expiryDate:
            structured.expiryDate ??
            _extractDateByKeywords(lines, const [
              'expiry',
              'exp',
              'best before',
              'use by',
            ]),
      );
    }

    return ScanPayloadModel(
      rawValue: normalizedText,
      codeFormat: 'ocr',
      recognizedText: normalizedText,
      productName: _guessProductName(lines),
      sku: _extractValue(lines, const [
        'sku',
        'item code',
        'product code',
        'code',
      ]),
      batchNumber: _extractValue(lines, const [
        'batch',
        'batch no',
        'lot',
        'lot no',
      ]),
      quantity: _extractQuantity(lines),
      manufacturedAt: _extractDateByKeywords(lines, const [
        'mfg',
        'mfd',
        'manufactured',
        'packed on',
        'pack date',
      ]),
      expiryDate: _extractDateByKeywords(lines, const [
        'expiry',
        'exp',
        'best before',
        'use by',
      ]),
    );
  }

  static Map<String, dynamic>? _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, entry) => MapEntry(key.toString(), entry));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Map<String, dynamic>? _tryParseKeyValuePairs(String value) {
    final normalized = value.replaceAll(';', '\n').replaceAll('|', '\n');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final result = <String, dynamic>{};
    for (final line in lines) {
      final separatorIndex = _findSeparatorIndex(line);
      if (separatorIndex == -1) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      final valuePart = line.substring(separatorIndex + 1).trim();
      if (key.isEmpty || valuePart.isEmpty) {
        continue;
      }

      result[key] = valuePart;
    }

    return result.isEmpty ? null : result;
  }

  static int _findSeparatorIndex(String value) {
    final colonIndex = value.indexOf(':');
    final equalsIndex = value.indexOf('=');

    if (colonIndex == -1) {
      return equalsIndex;
    }
    if (equalsIndex == -1) {
      return colonIndex;
    }

    return colonIndex < equalsIndex ? colonIndex : equalsIndex;
  }

  static String? _readString(Map<String, dynamic> map, List<String> aliases) {
    for (final alias in aliases) {
      for (final entry in map.entries) {
        if (_normalizeKey(entry.key) != _normalizeKey(alias)) {
          continue;
        }

        final value = entry.value?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  static int? _readInt(Map<String, dynamic> map, List<String> aliases) {
    final value = _readString(map, aliases);
    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }

  static DateTime? _readDate(Map<String, dynamic> map, List<String> aliases) {
    final value = _readString(map, aliases);
    if (value == null) {
      return null;
    }

    return _parseDate(value);
  }

  static String? _extractValue(List<String> lines, List<String> keywords) {
    for (final line in lines) {
      final normalizedLine = line.toLowerCase();
      for (final keyword in keywords) {
        if (!normalizedLine.contains(keyword)) {
          continue;
        }

        final match = RegExp(
          '${RegExp.escape(keyword)}\\s*[:#\\-]?\\s*([A-Za-z0-9\\-/ ]+)',
          caseSensitive: false,
        ).firstMatch(line);

        final extracted = match?.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return null;
  }

  static int? _extractQuantity(List<String> lines) {
    final value = _extractValue(lines, const ['qty', 'quantity', 'count']);
    if (value == null) {
      return null;
    }

    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  static DateTime? _extractDateByKeywords(
    List<String> lines,
    List<String> keywords,
  ) {
    for (final line in lines) {
      final normalizedLine = line.toLowerCase();
      final containsKeyword = keywords.any(normalizedLine.contains);
      if (!containsKeyword) {
        continue;
      }

      final dateFromLine = _extractFirstDate(line);
      if (dateFromLine != null) {
        return dateFromLine;
      }
    }

    return null;
  }

  static String? _guessProductName(List<String> lines) {
    for (final line in lines) {
      final normalizedLine = line.toLowerCase();
      if (RegExp(r'^\d+$').hasMatch(line)) {
        continue;
      }
      if (normalizedLine.contains('batch') ||
          normalizedLine.contains('lot') ||
          normalizedLine.contains('mfg') ||
          normalizedLine.contains('exp') ||
          normalizedLine.contains('best before') ||
          normalizedLine.contains('use by') ||
          normalizedLine.contains('qty') ||
          normalizedLine.contains('quantity')) {
        continue;
      }
      if (!RegExp(r'[A-Za-z]').hasMatch(line)) {
        continue;
      }

      return line;
    }

    return null;
  }

  static DateTime? _extractFirstDate(String value) {
    final patterns = [
      RegExp(r'(\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2})'),
      RegExp(r'(\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4})'),
      RegExp(r'(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})'),
      RegExp(r'([A-Za-z]{3,9}\s+\d{1,2},?\s+\d{2,4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);
      if (match == null) {
        continue;
      }

      final parsed = _parseDate(match.group(1)!);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static DateTime? _parseDate(String value) {
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final cleaned = value.trim().replaceAll('.', '/');
    final numericMatch = RegExp(
      r'^(\d{1,4})[\/\-](\d{1,2})[\/\-](\d{1,4})$',
    ).firstMatch(cleaned);
    if (numericMatch != null) {
      final first = int.tryParse(numericMatch.group(1)!);
      final second = int.tryParse(numericMatch.group(2)!);
      final third = int.tryParse(numericMatch.group(3)!);
      if (first != null && second != null && third != null) {
        if (numericMatch.group(1)!.length == 4) {
          return _safeDate(first, second, third);
        }
        if (numericMatch.group(3)!.length == 4) {
          if (first > 12) {
            return _safeDate(third, second, first);
          }
          return _safeDate(third, second, first);
        }
      }
    }

    final longMonthMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})$',
    ).firstMatch(cleaned);
    if (longMonthMatch != null) {
      final day = int.tryParse(longMonthMatch.group(1)!);
      final month = _monthFromName(longMonthMatch.group(2)!);
      final year = _normalizeYear(longMonthMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return _safeDate(year, month, day);
      }
    }

    final monthFirstMatch = RegExp(
      r'^([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{2,4})$',
    ).firstMatch(cleaned);
    if (monthFirstMatch != null) {
      final month = _monthFromName(monthFirstMatch.group(1)!);
      final day = int.tryParse(monthFirstMatch.group(2)!);
      final year = _normalizeYear(monthFirstMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return _safeDate(year, month, day);
      }
    }

    return null;
  }

  static int? _monthFromName(String monthName) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final normalized = monthName.substring(0, 3).toLowerCase();
    return months[normalized];
  }

  static int? _normalizeYear(String yearValue) {
    final year = int.tryParse(yearValue);
    if (year == null) {
      return null;
    }
    if (yearValue.length == 2) {
      return year >= 70 ? 1900 + year : 2000 + year;
    }
    return year;
  }

  static DateTime? _safeDate(int year, int month, int day) {
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
