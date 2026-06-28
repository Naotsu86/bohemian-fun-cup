Bohemian Fun Cup – saubere Projektstruktur

Wichtig:
Diese Datei/Ordnerstruktur ist erstmal ungefährlich.
Leere Ordner verursachen keine Fehler.
Damit GitHub leere Ordner trotzdem übernimmt, liegt in jedem vorbereiteten Ordner eine .gitkeep-Datei.

Aktuelle Dateien musst du noch NICHT verschieben.
Das hier ist nur das Fundament für die nächsten Schritte.

Geplante Struktur:

src/components/admin/
- später Admin-Login
- Spieler bearbeiten
- Avatar/Stats-Editor

src/components/games/
- Spielkarten
- Ergebnisanzeige
- Spiel-Erstellung

src/components/overview/
- Übersichtskarten
- Nächstes Spiel
- Regelkarte

src/components/ranking/
- Podium
- Rangliste
- Platzierungszeilen

src/components/shared/
- Buttons
- Dialoge
- Pixel-Fenster
- wiederverwendbare UI-Elemente

src/composables/
- später wiederverwendbare Vue-Logik
- z. B. useRanking, useAvatar, useAdminAuth

src/services/
- Supabase
- Ranking-Berechnung
- Spielgenerator
- Storage

src/styles/
- base.css
- component styles
- theme styles
- fonts

public/avatars/
- base: Basis-Pinguine
- head: Kopf-Accessoires
- face: Gesicht/Brille/Maske
- body: Kleidung/Schal/Bowtie
- back: Rücken/Flügel/Rucksack

public/icons/
- allgemeine Pixelicons

public/nav-icons/
- Bottom-Navigation

public/badges/
- Platz 1/2/3 Icons

public/banners/
- Header-Banner

public/themes/
- spätere Theme-Assets

Nächster sinnvoller Schritt:
1. Aktuelle Version stabil halten.
2. Danach einzelne Komponenten Schritt für Schritt verschieben.
3. Erst nach jedem Verschieben prüfen, ob GitHub Actions sauber durchläuft.
