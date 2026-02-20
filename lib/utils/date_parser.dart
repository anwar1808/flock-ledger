import 'dart:io';
import 'package:exif/exif.dart';
import 'package:intl/intl.dart';

/// Tries to extract a date from a file's name or EXIF data.
/// Returns null if neither works.
Future<DateTime?> parseDateFromPhoto(File file) async {
  // 1. Try filename patterns: IMG_20240315_..., 20240315_..., etc.
  final filename = file.path.split('/').last;
  final dateFromName = _parseDateFromFilename(filename);
  if (dateFromName != null) return dateFromName;

  // 2. Try EXIF data
  try {
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);
    if (data.containsKey('Image DateTime')) {
      final raw = data['Image DateTime']!.printable;
      // EXIF format: "2024:03:15 10:30:00"
      return _parseExifDate(raw);
    }
    if (data.containsKey('EXIF DateTimeOriginal')) {
      final raw = data['EXIF DateTimeOriginal']!.printable;
      return _parseExifDate(raw);
    }
  } catch (_) {
    // Ignore EXIF read failures
  }

  return null;
}

DateTime? _parseDateFromFilename(String filename) {
  // IMG_YYYYMMDD_...
  final imgPattern = RegExp(r'IMG_(\d{8})');
  final imgMatch = imgPattern.firstMatch(filename);
  if (imgMatch != null) {
    return _parseYYYYMMDD(imgMatch.group(1)!);
  }

  // YYYYMMDD_... or YYYY-MM-DD
  final datePattern = RegExp(r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})');
  final dateMatch = datePattern.firstMatch(filename);
  if (dateMatch != null) {
    try {
      return DateTime(
        int.parse(dateMatch.group(1)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(3)!),
      );
    } catch (_) {
      return null;
    }
  }

  return null;
}

DateTime? _parseYYYYMMDD(String s) {
  if (s.length != 8) return null;
  try {
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  } catch (_) {
    return null;
  }
}

DateTime? _parseExifDate(String raw) {
  try {
    // "2024:03:15 10:30:00"
    return DateFormat('yyyy:MM:dd HH:mm:ss').parse(raw);
  } catch (_) {
    return null;
  }
}
