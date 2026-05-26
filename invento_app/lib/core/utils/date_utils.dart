import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readDateTime(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
  }

  return fallback ?? DateTime.now();
}

Timestamp? toTimestamp(DateTime? value) {
  if (value == null) {
    return null;
  }

  return Timestamp.fromDate(value);
}

String formatShortDate(DateTime? value) {
  if (value == null) {
    return 'N/A';
  }

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

int? daysUntil(DateTime? value) {
  if (value == null) {
    return null;
  }

  return value.difference(DateTime.now()).inDays;
}
