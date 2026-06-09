import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'smoke_entry.dart';

// Erzeugt ein PDF mit einer Tabelle aller Einträge.
class PdfExporter {
  static Future<File> build(List<SmokeEntry> entries,
      {String titleSuffix = ''}) async {
    final doc = pw.Document();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    final headers = [
      'Nr', 'Datum/Zeit', 'Geruch', 'Sicht', 'Int.',
      'Kopfweh', 'Wind', 'km/h', '°C', 'hPa', 'Ausbreitung', 'Notiz'
    ];

    final rows = entries.map((e) {
      final headache = [
        if (e.headacheSelf) 'ich',
        if (e.headacheChild) 'Kind'
      ].join('/');
      return [
        e.id?.toString() ?? '',
        df.format(DateTime.parse(e.timestamp)),
        e.smellLabel,
        e.visibilityLabel,
        e.intensity.toString(),
        headache.isEmpty ? '—' : headache,
        e.windCompass,
        e.windSpeed?.toStringAsFixed(0) ?? '—',
        e.temperature?.toStringAsFixed(0) ?? '—',
        e.pressure?.toStringAsFixed(0) ?? '—',
        e.dispersion ?? '—',
        e.note ?? '',
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Immissionsprotokoll Rauchbelastung $titleSuffix',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(
              text: 'Erstellt: ${df.format(DateTime.now())}  •  '
                  'Anzahl Einträge: ${entries.length}'),
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 7),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FixedColumnWidth(70),
              11: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Paragraph(
              text: 'Hinweis: Zeitstempel werden bei der Erfassung '
                  'automatisch gesetzt. GPS-Koordinaten und Wetterdaten '
                  '(Quelle: Open-Meteo) werden zum Zeitpunkt der Erfassung '
                  'automatisch ergänzt.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rauchprotokoll_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
