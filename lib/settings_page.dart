import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _useFixed = false;
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _useFixed = p.getBool('useFixedLocation') ?? false;
      _lat.text = (p.getDouble('fixedLat') ?? '').toString();
      _lon.text = (p.getDouble('fixedLon') ?? '').toString();
      _email.text = p.getString('reportEmail') ?? '';
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('useFixedLocation', _useFixed);
    final lat = double.tryParse(_lat.text.replaceAll(',', '.'));
    final lon = double.tryParse(_lon.text.replaceAll(',', '.'));
    if (lat != null) await p.setDouble('fixedLat', lat);
    if (lon != null) await p.setDouble('fixedLon', lon);
    await p.setString('reportEmail', _email.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gespeichert.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Standort für Wetterdaten',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _useFixed,
            onChanged: (v) => setState(() => _useFixed = v),
            title: const Text('Feste Koordinaten verwenden'),
            subtitle: Text(_useFixed
                ? 'Feste Koordinaten der Wohnung'
                : 'GPS des Handys (Standard)'),
          ),
          if (_useFixed) ...[
            TextField(
              controller: _lat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Breitengrad (z.B. 47.3769)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lon,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Längengrad (z.B. 8.5417)',
                  border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Monatsbericht',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Empfänger-E-Mail',
                hintText: 'meine.adresse@gmx.ch',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beim Senden öffnet sich deine Mail-App mit fertigem Betreff '
            'und angehängtem PDF – du musst nur noch auf „Senden" tippen.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
    );
  }
}
