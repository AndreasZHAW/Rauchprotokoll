# Rauchprotokoll – Web-App

Eine reine Webseite (HTML/CSS/JavaScript) zur Dokumentation von Rauch-/Abgasbelastung.
Läuft im Browser, speichert Daten lokal auf dem Gerät, kein Server nötig.

## Über GitHub Pages veröffentlichen

1. Konto auf https://github.com erstellen (falls noch keins).
2. Oben rechts auf **+** → **New repository**.
3. Namen vergeben, z.B. `rauchprotokoll`. Auf **Public** lassen. **Create repository**.
4. Auf der nächsten Seite **uploading an existing file** anklicken.
5. Die drei Dateien `index.html`, `style.css`, `app.js` hineinziehen und **Commit changes**.
6. Im Repository oben auf **Settings** → links auf **Pages**.
7. Unter „Branch" **main** wählen, Ordner **/(root)**, **Save**.
8. Nach 1–2 Minuten erscheint oben die Adresse, z.B.
   `https://deinname.github.io/rauchprotokoll/` – das ist deine App.

Diese Adresse kannst du auf dem Handy öffnen und über das Browser-Menü
„Zum Startbildschirm hinzufügen" – dann hast du ein App-Symbol.

## Wichtig zu wissen

- **Daten liegen lokal im Browser** (localStorage). Wenn du die Browser-Daten
  löschst oder das Gerät wechselst, sind sie weg. Nutze daher regelmäßig
  **„Backup speichern"** im Reiter Auswertung. Wiederherstellen geht über
  **„Backup wiederherstellen"**.
- **Fotos** werden verkleinert und lokal gespeichert. Bei sehr vielen Fotos
  kann der Browser-Speicher knapp werden – das Backup enthält sie mit.
- **GPS & Wetter**: Der Browser fragt einmalig nach Standort-Erlaubnis.
  Wetterdaten kommen von Open-Meteo (kostenlos). Funktioniert nur online.
- **Monatsbericht**: Das PDF wird heruntergeladen, dann öffnet sich deine
  Mail-App mit fertigem Betreff – das PDF musst du selbst anhängen
  (technische Grenze des Browsers).

## Rechtliche Dokumentation

Die App erfasst pro Vorfall: Zeitstempel, fortlaufende ID, Geruchsart,
Sichtbarkeit, Stärke 1–5, betroffene Räume, Fensterzustand, Maßnahmen,
Gesundheitssymptome, GPS, Wind, Temperatur, Luftdruck, Feuchte, Foto.

Zusätzlich empfehlenswert: zeitnah und lückenlos dokumentieren, Zeugen
notieren, Arztbesuche dokumentieren lassen, Schriftverkehr aufbewahren,
ggf. zuständige Behörde informieren. Das ist allgemeine Information,
keine Rechtsberatung.
