Fix:
Die Badges waren nicht sichtbar, weil im alten CSS vermutlich .rank-badge ausgeblendet wurde.
Deshalb nutzt diese Version eine neue Klasse: .dynamic-rank-badge

Aufbau:
- Platz 1-3 bleiben im Podium.
- Platz 4-99 werden rechts als blau/weiß/roter Badge dargestellt.
- Die Zahl wird dynamisch darübergelegt.
- Name/Punkte/Details bleiben links wie im Podium.

Dateien ersetzen:
src/components/RankingTable.vue
src/views/Ranking.vue
src/style.css
public/icons/rank-badge-empty.svg
