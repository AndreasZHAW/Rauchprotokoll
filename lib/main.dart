import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'capture_tab.dart';
import 'calendar_tab.dart';
import 'stats_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  runApp(const RauchApp());
}

class RauchApp extends StatelessWidget {
  const RauchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rauchprotokoll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // GlobalKey, damit Kalender/Statistik nach dem Speichern neu laden.
  final _refresh = ValueNotifier<int>(0);

  late final List<Widget> _pages = [
    CaptureTab(onSaved: () => _refresh.value++),
    CalendarTab(refresh: _refresh),
    StatsTab(refresh: _refresh),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.add_alert_outlined),
              selectedIcon: Icon(Icons.add_alert),
              label: 'Erfassen'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Kalender'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Auswertung'),
        ],
      ),
    );
  }
}
