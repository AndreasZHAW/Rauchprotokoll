# Rauchprotokoll – App bauen & installieren

Diese Anleitung führt dich Schritt für Schritt von „nichts installiert" bis zur
fertigen APK auf deinem Android-12-Handy. Du brauchst dafür keinen Play Store.

---

## Überblick: Was du tust

1. Flutter (das Entwickler-Werkzeug) installieren
2. Den mitgelieferten Quellcode in ein frisches Flutter-Projekt legen
3. Berechtigungen eintragen
4. APK bauen
5. APK auf dein Handy kopieren und installieren

Plane ca. 1–1,5 Stunden ein (das meiste sind Downloads).

---

## Schritt 1 – Flutter installieren

**Windows / Mac / Linux:** Folge der offiziellen Anleitung:
https://docs.flutter.dev/get-started/install

Du brauchst zusätzlich:
- **Android Studio** (enthält das Android-SDK) – kostenlos:
  https://developer.android.com/studio
- Beim ersten Start von Android Studio die **Android-SDK-Lizenzen akzeptieren**.

Prüfe danach im Terminal / in der Eingabeaufforderung:

```
flutter doctor
```

Alles mit ✓ ist gut. Falls Android-Lizenzen fehlen:

```
flutter doctor --android-licenses
```
(mehrfach „y" eingeben)

---

## Schritt 2 – Projekt anlegen und Code einsetzen

1. Erstelle ein leeres Flutter-Projekt:
   ```
   flutter create rauchprotokoll
   ```
2. Im neuen Ordner `rauchprotokoll/` findest du u.a. `lib/` und `pubspec.yaml`.
3. **Ersetze** die Datei `pubspec.yaml` durch die mitgelieferte.
4. **Lösche** die vorhandene `lib/main.dart` und **kopiere alle Dateien aus
   dem mitgelieferten `lib/`-Ordner hinein**:
   - `main.dart`
   - `smoke_entry.dart`
   - `database_helper.dart`
   - `weather_service.dart`
   - `pdf_exporter.dart`
   - `capture_tab.dart`
   - `calendar_tab.dart`
   - `stats_tab.dart`
   - `settings_page.dart`

5. Pakete laden:
   ```
   cd rauchprotokoll
   flutter pub get
   ```

---

## Schritt 3 – Berechtigungen eintragen

Öffne `android/app/src/main/AndroidManifest.xml`.
Füge die Zeilen aus der mitgelieferten Datei `MANIFEST_PERMISSIONS.txt`
**innerhalb** des `<manifest ...>`-Tags ein, direkt **vor** `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### minSdk setzen (für Kamera/Standort empfohlen)
Öffne `android/app/build.gradle` und stelle sicher, dass steht:
```
minSdkVersion 21
```
(oder höher; falls dort `flutter.minSdkVersion` steht, ist das auch ok)

---

## Schritt 4 – APK bauen

Handy noch nicht nötig. Im Projektordner:

```
flutter build apk --release
```

Nach einigen Minuten liegt die fertige Datei hier:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Schritt 5 – Auf dem Handy installieren

**Variante A – per Kabel (am einfachsten):**
1. Handy per USB anschließen, „USB-Debugging" in den Entwickleroptionen aktivieren.
2. Im Terminal:
   ```
   flutter install
   ```
   Die App wird direkt installiert.

**Variante B – APK-Datei kopieren:**
1. `app-release.apk` per Kabel / Mail / Cloud auf das Handy bringen.
2. Datei auf dem Handy antippen.
3. „Installation aus unbekannten Quellen" für deinen Dateimanager erlauben.
4. Installieren.

Beim ersten Start fragt die App nach **Kamera-** und **Standort-Berechtigung** –
beide erlauben, sonst fehlen Foto bzw. Wetterdaten.

---

## Erste Schritte in der App

1. Gehe einmal in **Einstellungen** (Zahnrad oben rechts) und trage deine
   **GMX-E-Mail** für den Monatsbericht ein.
2. GPS ist Standard. Wenn du lieber feste Koordinaten deiner Wohnung willst,
   schalte „Feste Koordinaten" an und trage Breiten-/Längengrad ein
   (findest du z.B. über Google Maps → Rechtsklick → Koordinaten).

---

## Hinweise & Grenzen

- **Wetterquelle:** Open-Meteo (kostenlos, kein Konto nötig). Bei keinem
  Internet/GPS wird der Eintrag trotzdem gespeichert – nur ohne Wetter.
- **Ausbreitung „steigt auf / sinkt"** ist eine grobe Faustregel aus
  Temperatur/Luftdruck/Feuchte, kein Messwert. Für Gerichtsverwertbarkeit
  zählt vor allem die lückenlose, zeitgestempelte Dokumentation.
- **Monatsbericht:** Eine App kann unter Android nicht zuverlässig vollautomatisch
  und unbeaufsichtigt E-Mails versenden. Deshalb der 1-Klick-Weg: PDF wird erzeugt,
  Mail-App öffnet sich vorausgefüllt, du tippst nur „Senden". Du kannst dir im
  Handy-Kalender eine monatliche Erinnerung setzen.
- **Backup:** Nutze regelmäßig „Textdaten teilen" und „Als PDF exportieren",
  damit du außerhalb des Handys eine Kopie hast.

---

## Rechtliche Dokumentation – was die App schon erfasst

Die App erfasst pro Vorfall automatisch oder per Tipp:
Zeitstempel, fortlaufende ID, Geruchsart, Sichtbarkeit, Stärke 1–5,
betroffene Räume, Fensterzustand, Maßnahmen, Gesundheitssymptome,
GPS, Wind (Richtung/Stärke), Temperatur, Luftdruck, Feuchte, Foto.

**Zusätzlich empfehlenswert (außerhalb der App):**
- Vorfälle möglichst zeitnah und immer gleich dokumentieren (Lückenlosigkeit).
- Zeugen notieren (Name, was sie wahrgenommen haben).
- Bei gesundheitlichen Beschwerden: Arztbesuch dokumentieren lassen.
- Schriftverkehr mit Nachbar/Hausverwaltung/Behörde aufbewahren.
- Ggf. die zuständige Behörde (in der Schweiz je nach Kanton/Gemeinde das
  Umwelt- oder Bauamt) informieren – das Protokoll dient dann als Grundlage.

Hinweis: Das ist allgemeine Information, keine Rechtsberatung. Für die
konkrete Durchsetzung lohnt sich eine kurze Beratung bei einer Rechtsauskunft
oder einem Anwalt.
