import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'smoke_entry.dart';
import 'database_helper.dart';

class CalendarTab extends StatefulWidget {
  final ValueNotifier<int> refresh;
  const CalendarTab({super.key, required this.refresh});
  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  Map<DateTime, List<SmokeEntry>> _byDay = {};
  DateTime _focused = DateTime.now();
  DateTime? _selected;

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
    final map = <DateTime, List<SmokeEntry>>{};
    for (final e in all) {
      final d = DateTime.parse(e.timestamp);
      final key = DateTime.utc(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    if (mounted) setState(() => _byDay = map);
  }

  List<SmokeEntry> _eventsFor(DateTime day) {
    return _byDay[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selected == null ? <SmokeEntry>[] : _eventsFor(_selected!);
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: Column(
        children: [
          TableCalendar<SmokeEntry>(
            locale: 'de_DE',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(_selected, d),
            eventLoader: _eventsFor,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (sel, foc) =>
                setState(() {
              _selected = sel;
              _focused = foc;
            }),
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: Colors.teal.shade200, shape: BoxShape.circle),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(_selected == null
                        ? 'Tag antippen, um Einträge zu sehen.'
                        : 'Keine Belastung an diesem Tag.'))
                : ListView(
                    children: selectedEvents.map(_detailCard).toList()),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(SmokeEntry e) {
    final t = DateFormat('HH:mm').format(DateTime.parse(e.timestamp));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: e.smellToxic ? Colors.red : Colors.teal,
          child: Text('$t'.substring(0, 2),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text('$t Uhr  •  ${e.smellLabel}'),
        subtitle: Text(
            '${e.visibilityLabel} • Stärke ${e.intensity}/5'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Kopfweh',
                    [if (e.headacheSelf) 'ich', if (e.headacheChild) 'Kind']
                            .join(', ')
                            .isEmpty
                        ? 'nein'
                        : [if (e.headacheSelf) 'ich', if (e.headacheChild) 'Kind']
                            .join(', ')),
                _row('Fenster', e.windowState),
                _row('Räume', e.affectedRooms ?? '—'),
                _row('Wind',
                    '${e.windCompass} • ${e.windSpeed?.toStringAsFixed(0) ?? "—"} km/h'),
                _row('Temperatur',
                    '${e.temperature?.toStringAsFixed(1) ?? "—"} °C'),
                _row('Luftdruck',
                    '${e.pressure?.toStringAsFixed(0) ?? "—"} hPa'),
                _row('Ausbreitung', e.dispersion ?? '—'),
                _row('Maßnahmen', e.measures ?? '—'),
                _row('Notiz', e.note ?? '—'),
                if (e.photoPath != null && File(e.photoPath!).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(e.photoPath!),
                          height: 150, fit: BoxFit.cover),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Löschen',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      await DatabaseHelper.instance.delete(e.id!);
                      widget.refresh.value++;
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(k,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(v)),
        ]),
      );
}
