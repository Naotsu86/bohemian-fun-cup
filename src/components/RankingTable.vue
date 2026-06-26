<template><div class="table-wrap"><table><thead><tr><th>Platz</th><th>Spieler</th><th>Punkte</th><th>Spiele</th><th>Siege</th><th>Ø</th></tr></thead><tbody><tr v-for="(r,i) in rows" :key="r.id"><td class="place">{{ medal(i) }}</td><td><b>{{ r.name }}</b></td><td>{{ r.points }}</td><td>{{ r.games }}</td><td>{{ r.wins }}</td><td>{{ r.avg }}</td></tr></tbody></table></div></template>
<script setup>
defineProps({ rows: Array })
function medal(i){return i===0?'🥇':i===1?'🥈':i===2?'🥉':i+1}
</script>
