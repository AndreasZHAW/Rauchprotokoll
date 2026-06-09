import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holt Standort (GPS oder fest) und Wetterdaten von Open-Meteo.
class WeatherService {
  // Liefert [lat, lon] je nach Einstellung.
  static Future<List<double>?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final useFixed = prefs.getBool('useFixedLocation') ?? false;

    if (useFixed) {
      final lat = prefs.getDouble('fixedLat');
      final lon = prefs.getDouble('fixedLon');
      if (lat != null && lon != null) return [lat, lon];
      return null;
    }

    // GPS
    try {
      bool service = await Geolocator.isLocationServiceEnabled();
      if (!service) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return [pos.latitude, pos.longitude];
    } catch (_) {
      return null;
    }
  }

  // Holt aktuelle Wetterwerte. Gibt eine Map mit den Feldern zurück.
  static Future<Map<String, dynamic>?> fetchWeather(
      double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,surface_pressure,'
        'wind_speed_10m,wind_direction_10m');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final c = data['current'];
      final temp = (c['temperature_2m'] as num?)?.toDouble();
      final hum = (c['relative_humidity_2m'] as num?)?.toDouble();
      final pres = (c['surface_pressure'] as num?)?.toDouble();
      final wspd = (c['wind_speed_10m'] as num?)?.toDouble();
      final wdir = (c['wind_direction_10m'] as num?)?.toDouble();
      return {
        'temperature': temp,
        'humidity': hum,
        'pressure': pres,
        'windSpeed': wspd,
        'windDirection': wdir,
        'dispersion': _estimateDispersion(temp, pres, hum),
      };
    } catch (_) {
      return null;
    }
  }

  // Grobe Faustregel zur Rauchausbreitung.
  // Hoher Luftdruck + kühl/feucht -> Inversion wahrscheinlich -> Rauch sinkt.
  // Niedriger Druck + warm + trocken -> Rauch steigt eher auf.
  static String _estimateDispersion(double? temp, double? pres, double? hum) {
    if (temp == null || pres == null) return 'neutral';
    double score = 0;
    if (pres > 1020) score -= 1;      // Hochdruck -> stabile Schichtung
    if (pres < 1005) score += 1;      // Tiefdruck -> labil
    if (temp > 15) score += 1;        // warm -> Thermik
    if (temp < 5) score -= 1;         // kalt -> bodennah
    if ((hum ?? 0) > 85) score -= 1;  // sehr feucht/neblig -> bodennah
    if (score >= 1) return 'steigt auf';
    if (score <= -1) return 'sinkt zu Boden';
    return 'neutral';
  }
}
