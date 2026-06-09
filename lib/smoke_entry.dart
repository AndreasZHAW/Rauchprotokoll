// Datenmodell für einen einzelnen Rauch-Eintrag.
class SmokeEntry {
  int? id;
  String timestamp;        // ISO-8601, automatisch gesetzt (unveränderlich)
  String? endTimestamp;    // optionales Ende der Belastung
  bool smellWood;          // riecht nach (normalem) Holz
  bool smellToxic;         // riecht giftig/chemisch (z.B. beschichtetes Holz)
  bool visibleLight;       // leicht sichtbarer Rauch
  bool visibleStrong;      // stark sichtbarer Rauch
  int intensity;           // Stärke 1-5 (subjektiv)
  bool headacheSelf;       // Kopfweh bei mir
  bool headacheChild;      // Kopfweh bei Kind(ern)
  String? affectedRooms;   // betroffene Räume
  String windowState;      // 'offen' / 'geschlossen' / 'unbekannt'
  String? measures;        // ergriffene Maßnahmen
  String? note;            // Freitext-Notiz
  String? photoPath;       // lokaler Pfad zum Foto

  // Standort
  double? latitude;
  double? longitude;

  // Wetter (Open-Meteo)
  double? temperature;     // °C
  double? pressure;        // hPa
  double? humidity;        // %
  double? windSpeed;       // km/h
  double? windDirection;   // Grad (0 = Nord)
  String? dispersion;      // abgeleitet: "steigt auf" / "sinkt" / "neutral"

  SmokeEntry({
    this.id,
    required this.timestamp,
    this.endTimestamp,
    this.smellWood = false,
    this.smellToxic = false,
    this.visibleLight = false,
    this.visibleStrong = false,
    this.intensity = 3,
    this.headacheSelf = false,
    this.headacheChild = false,
    this.affectedRooms,
    this.windowState = 'unbekannt',
    this.measures,
    this.note,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.temperature,
    this.pressure,
    this.humidity,
    this.windSpeed,
    this.windDirection,
    this.dispersion,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp,
        'endTimestamp': endTimestamp,
        'smellWood': smellWood ? 1 : 0,
        'smellToxic': smellToxic ? 1 : 0,
        'visibleLight': visibleLight ? 1 : 0,
        'visibleStrong': visibleStrong ? 1 : 0,
        'intensity': intensity,
        'headacheSelf': headacheSelf ? 1 : 0,
        'headacheChild': headacheChild ? 1 : 0,
        'affectedRooms': affectedRooms,
        'windowState': windowState,
        'measures': measures,
        'note': note,
        'photoPath': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'temperature': temperature,
        'pressure': pressure,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'dispersion': dispersion,
      };

  factory SmokeEntry.fromMap(Map<String, dynamic> m) => SmokeEntry(
        id: m['id'] as int?,
        timestamp: m['timestamp'] as String,
        endTimestamp: m['endTimestamp'] as String?,
        smellWood: (m['smellWood'] ?? 0) == 1,
        smellToxic: (m['smellToxic'] ?? 0) == 1,
        visibleLight: (m['visibleLight'] ?? 0) == 1,
        visibleStrong: (m['visibleStrong'] ?? 0) == 1,
        intensity: (m['intensity'] ?? 3) as int,
        headacheSelf: (m['headacheSelf'] ?? 0) == 1,
        headacheChild: (m['headacheChild'] ?? 0) == 1,
        affectedRooms: m['affectedRooms'] as String?,
        windowState: (m['windowState'] ?? 'unbekannt') as String,
        measures: m['measures'] as String?,
        note: m['note'] as String?,
        photoPath: m['photoPath'] as String?,
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
        temperature: m['temperature'] as double?,
        pressure: m['pressure'] as double?,
        humidity: m['humidity'] as double?,
        windSpeed: m['windSpeed'] as double?,
        windDirection: m['windDirection'] as double?,
        dispersion: m['dispersion'] as String?,
      );

  // Windrichtung als Himmelsrichtung (woher der Wind kommt).
  String get windCompass {
    if (windDirection == null) return '—';
    const dirs = ['N', 'NO', 'O', 'SO', 'S', 'SW', 'W', 'NW'];
    return dirs[((windDirection! % 360) / 45).round() % 8];
  }

  String get smellLabel {
    final parts = <String>[];
    if (smellWood) parts.add('Holz');
    if (smellToxic) parts.add('giftig/chemisch');
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String get visibilityLabel {
    if (visibleStrong) return 'stark sichtbar';
    if (visibleLight) return 'leicht sichtbar';
    return '—';
  }
}
