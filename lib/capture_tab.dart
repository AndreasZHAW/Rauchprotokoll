import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'smoke_entry.dart';
import 'database_helper.dart';
import 'weather_service.dart';
import 'settings_page.dart';

class CaptureTab extends StatefulWidget {
  final VoidCallback onSaved;
  const CaptureTab({super.key, required this.onSaved});
  @override
  State<CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<CaptureTab> {
  bool _smellWood = false;
  bool _smellToxic = false;
  bool _visLight = false;
  bool _visStrong = false;
  int _intensity = 3;
  bool _headSelf = false;
  bool _headChild = false;
  String _window = 'unbekannt';
  final _rooms = TextEditingController();
  final _measures = TextEditingController();
  final _note = TextEditingController();
  String? _photoPath;

  void _reset() {
    setState(() {
      _smellWood = _smellToxic = _visLight = _visStrong = false;
      _headSelf = _headChild = false;
      _intensity = 3;
      _window = 'unbekannt';
      _rooms.clear();
      _measures.clear();
      _note.clear();
      _photoPath = null;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
    if (x == null) return;
    // Foto dauerhaft im App-Verzeichnis speichern.
    final dir = await getApplicationDocumentsDirectory();
    final name = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(x.path).copy(p.join(dir.path, name));
    setState(() => _photoPath = saved.path);
  }

  Future<void> _save() async {
    if (!_smellWood && !_smellToxic && !_visLight && !_visStrong) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte mindestens Geruch oder Sichtbarkeit wählen.')));
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    final now = DateTime.now().toIso8601String();
    final entry = SmokeEntry(
      timestamp: now,
      smellWood: _smellWood,
      smellToxic: _smellToxic,
      visibleLight: _visLight,
      visibleStrong: _visStrong,
      intensity: _intensity,
      headacheSelf: _headSelf,
      headacheChild: _headChild,
      affectedRooms: _rooms.text.trim().isEmpty ? null : _rooms.text.trim(),
      windowState: _window,
      measures: _measures.text.trim().isEmpty ? null : _measures.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      photoPath: _photoPath,
    );

    // Standort + Wetter im Hintergrund holen.
    final loc = await WeatherService.getLocation();
    if (loc != null) {
      entry.latitude = loc[0];
      entry.longitude = loc[1];
      final w = await WeatherService.fetchWeather(loc[0], loc[1]);
      if (w != null) {
        entry.temperature = w['temperature'];
        entry.humidity = w['humidity'];
        entry.pressure = w['pressure'];
        entry.windSpeed = w['windSpeed'];
        entry.windDirection = w['windDirection'];
        entry.dispersion = w['dispersion'];
      }
    }

    await DatabaseHelper.instance.insert(entry);
    if (!mounted) return;
    Navigator.pop(context); // Ladekreis schließen
    widget.onSaved();
    _reset();

    final msg = loc == null
        ? 'Gespeichert (ohne Standort/Wetter – GPS prüfen).'
        : 'Eintrag gespeichert.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eingabe löschen?'),
        content: const Text('Alle Felder dieses Eintrags werden verworfen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _reset();
              },
              child: const Text('Löschen')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rauch erfassen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Geruch'),
          Row(children: [
            Expanded(
                child: _bigToggle('Riecht nach Holz', Icons.park, _smellWood,
                    () => setState(() => _smellWood = !_smellWood))),
            const SizedBox(width: 10),
            Expanded(
                child: _bigToggle('Giftig / chemisch', Icons.warning_amber,
                    _smellToxic, () => setState(() => _smellToxic = !_smellToxic),
                    danger: true)),
          ]),
          const SizedBox(height: 16),
          _section('Sichtbarkeit'),
          Row(children: [
            Expanded(
                child: _bigToggle('Leicht sichtbar', Icons.visibility_outlined,
                    _visLight, () => setState(() {
                          _visLight = true;
                          _visStrong = false;
                        }))),
            const SizedBox(width: 10),
            Expanded(
                child: _bigToggle('Stark sichtbar', Icons.visibility,
                    _visStrong, () => setState(() {
                          _visStrong = true;
                          _visLight = false;
                        }))),
          ]),
          const SizedBox(height: 16),
          _section('Stärke: $_intensity / 5'),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_intensity',
            onChanged: (v) => setState(() => _intensity = v.round()),
          ),
          const SizedBox(height: 8),
          _section('Gesundheit'),
          CheckboxListTile(
            value: _headSelf,
            onChanged: (v) => setState(() => _headSelf = v ?? false),
            title: const Text('Kopfweh bei mir'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _headChild,
            onChanged: (v) => setState(() => _headChild = v ?? false),
            title: const Text('Kopfweh bei Kind(ern)'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          _section('Details (optional)'),
          DropdownButtonFormField<String>(
            value: _window,
            decoration: const InputDecoration(
                labelText: 'Fenster', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'unbekannt', child: Text('unbekannt')),
              DropdownMenuItem(value: 'offen', child: Text('offen')),
              DropdownMenuItem(
                  value: 'geschlossen', child: Text('geschlossen')),
            ],
            onChanged: (v) => setState(() => _window = v ?? 'unbekannt'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _rooms,
            decoration: const InputDecoration(
                labelText: 'Betroffene Räume',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _measures,
            decoration: const InputDecoration(
                labelText: 'Ergriffene Maßnahmen',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Notiz', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _section('Foto'),
          if (_photoPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_photoPath!), height: 160,
                    width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(_photoPath == null ? 'Foto aufnehmen' : 'Neues Foto'),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _confirmDiscard,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Eingabe löschen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                label: const Text('Speichern'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Text(
            'Datum, Uhrzeit, GPS und Wetter (Wind, Temperatur, Luftdruck) '
            'werden automatisch erfasst.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _bigToggle(String label, IconData icon, bool active, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? Colors.red : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
              color: active ? color : Colors.grey.shade400,
              width: active ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: active ? color : Colors.grey, size: 28),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? color : Colors.black87,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}
