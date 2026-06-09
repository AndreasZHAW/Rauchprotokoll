import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'smoke_entry.dart';
import 'database_helper.dart';
import 'pdf_exporter.dart';

class StatsTab extends StatefulWidget {
  final ValueNotifier<int> refresh;
  const StatsTab({super.key, required this.refresh});
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  List<SmokeEntry> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
    widget.refresh.addListener(_load);
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getAll();
    if (mounted) setState(() => _all = all);
  }

  // Einträge pro Monat (letzte 6 Monate) für das Balkendiagramm.
  Map<String, int> _perMonth() {
    final map = <String, int>{};
    final df = DateFormat('MM/yy');
    for (final e in _all) {
      final k = df.format(DateTime.parse(e.timestamp));
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _exportPdf() async {
    if (_all.isEmpty) return;
    final file = await PdfExporter.build(_all);
    await Printing.sharePdf(
        bytes: await file.readAsBytes(), filename: 'rauchprotokoll.pdf');
  }

  Future<void> _exportText() async {
    if (_all.isEmpty) return;
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final buf = StringBuffer('Rauchprotokoll – Export\n\n');
    for (final e in _all) {
      buf.writeln('${df.format(DateTime.parse(e.timestamp))} | '
          'Geruch: ${e.smellLabel} | ${e.visibilityLabel} | '
          'Stärke ${e.intensity}/5 | Wind ${e.windCompass} '
          '${e.windSpeed?.toStringAsFixed(0) ?? "—"}km/h | '
          '${e.temperature?.toStringAsFixed(0) ?? "—"}°C | '
          '${e.pressure?.toStringAsFixed(0) ?? "—"}hPa | '
          '${e.dispersion ?? "—"} | ${e.note ?? ""}');
    }
    await Share.share(buf.toString(), subject: 'Rauchprotokoll Export');
  }

  // Monatsbericht: PDF erzeugen, dann Mail-App mit Empfänger + Text öffnen.
  Future<void> _monthlyReport() async {
    final prefs = await SharedPreferences.getInstance();
    final to = prefs.getString('reportEmail') ?? '';

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final monthEntries = _all.where((e) {
      final d = DateTime.parse(e.timestamp);
      return d.year == lastMonth.year && d.month == lastMonth.month;
    }).toList();

    if (monthEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keine Einträge im Vormonat.')));
      return;
    }

    final monthName = DateFormat('MMMM yyyy', 'de_DE').format(lastMonth);
    final file =
        await PdfExporter.build(monthEntries, titleSuffix: '– $monthName');

    // 1) PDF teilen (an Mail-App), 2) zusätzlich mailto öffnen für Komfort.
    await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'rauchprotokoll_monat.pdf');

    if (to.isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: to,
        query: 'subject=Rauchprotokoll $monthName'
            '&body=Anbei das Rauchprotokoll für $monthName '
            '(${monthEntries.length} Einträge). Bitte PDF anhängen.',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final toxic = _all.where((e) => e.smellToxic).length;
    final wood = _all.where((e) => e.smellWood).length;
    final headache =
        _all.where((e) => e.headacheSelf || e.headacheChild).length;
    final perMonth = _perMonth();
    final months = perMonth.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Auswertung')),
      body: _all.isEmpty
          ? const Center(child: Text('Noch keine Einträge.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _stat('Gesamt', _all.length.toString(), Colors.teal),
                  _stat('Giftig', toxic.toString(), Colors.red),
                  _stat('Holz', wood.toString(), Colors.brown),
                  _stat('Mit Kopfweh', headache.toString(), Colors.orange),
                ]),
                const SizedBox(height: 24),
                const Text('Einträge pro Monat',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= months.length) {
                              return const SizedBox();
                            }
                            return Text(months[i],
                                style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < months.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                              toY: perMonth[months[i]]!.toDouble(),
                              color: Colors.teal,
                              width: 18,
                              borderRadius: BorderRadius.circular(4))
                        ])
                    ],
                  )),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Als PDF-Tabelle exportieren'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _exportText,
                  icon: const Icon(Icons.share),
                  label: const Text('Textdaten teilen'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _monthlyReport,
                  icon: const Icon(Icons.email),
                  label: const Text('Monatsbericht per Mail senden'),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label),
        ]),
      );
}
