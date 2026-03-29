import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/egg_record.dart';
import '../models/chicken.dart';
import '../models/chick_batch.dart';

final _dateFormatter = DateFormat('yyyy-MM-dd');

/// Generates and shares an Excel file with egg records and hatch data.
Future<void> exportToExcel({
  required List<EggRecord> eggRecords,
  required List<Chicken> chickens,
  required List<ChickBatch> batches,
}) async {
  final excel = Excel.createExcel();

  // ─── Sheet 1: Egg Records ───
  final eggSheet = excel['Egg Records'];
  _addEggRecordsSheet(eggSheet, eggRecords, chickens);

  // ─── Sheet 2: Clutch / Hatch Data ───
  final hatchSheet = excel['Clutch Hatch Data'];
  _addHatchSheet(hatchSheet, batches);

  // Remove the default "Sheet1" that Excel creates
  excel.delete('Sheet1');

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Failed to encode Excel file.');
  }

  // Save to a temporary file
  final dir = await getTemporaryDirectory();
  final filename =
      'FlockLedger_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);

  // Share via the system share sheet
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'FlockLedger Export — $filename',
  );
}

void _addEggRecordsSheet(
    Sheet sheet, List<EggRecord> records, List<Chicken> chickens) {
  // Build chicken lookup
  final chickenMap = {for (final c in chickens) c.id: c.name};

  // Header row
  sheet.appendRow([
    TextCellValue('Date'),
    TextCellValue('Chicken'),
    TextCellValue('Weight (g)'),
    TextCellValue('Size Grade'),
    TextCellValue('Egg Colour'),
    TextCellValue('Notes'),
  ]);

  // Data rows sorted by date ascending
  final sorted = List<EggRecord>.from(records)
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final r in sorted) {
    final chickenName = r.chickenId != null
        ? (chickenMap[r.chickenId!] ?? 'Unknown')
        : r.breedNote ?? 'Unassigned';

    sheet.appendRow([
      TextCellValue(_dateFormatter.format(r.date)),
      TextCellValue(chickenName),
      DoubleCellValue(r.weightGrams),
      TextCellValue(r.sizeGrade),
      TextCellValue(r.eggColorCategory.replaceAll('_', ' ')),
      TextCellValue(r.notes ?? ''),
    ]);
  }
}

void _addHatchSheet(Sheet sheet, List<ChickBatch> batches) {
  // Header row
  sheet.appendRow([
    TextCellValue('Clutch Name'),
    TextCellValue('Breed'),
    TextCellValue('Start Date'),
    TextCellValue('Expected Hatch Date'),
    TextCellValue('Eggs Set'),
    TextCellValue('Eggs Hatched'),
    TextCellValue('Hatch Rate %'),
    TextCellValue('Status'),
    TextCellValue('Notes'),
  ]);

  for (final b in batches) {
    final hatchRateStr = b.hatchRate != null
        ? '${b.hatchRate!.toStringAsFixed(1)}%'
        : 'Pending';

    sheet.appendRow([
      TextCellValue(b.name),
      TextCellValue(b.breed ?? ''),
      TextCellValue(_dateFormatter.format(b.startDate)),
      TextCellValue(_dateFormatter.format(b.expectedHatchDate)),
      IntCellValue(b.eggCount),
      b.eggsHatched != null
          ? IntCellValue(b.eggsHatched!)
          : TextCellValue('—'),
      TextCellValue(hatchRateStr),
      TextCellValue(b.status),
      TextCellValue(b.notes ?? ''),
    ]);
  }
}
