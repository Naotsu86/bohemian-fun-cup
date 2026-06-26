<template><div class="podium"><div v-for="(row,index) in topRows" :key="row.id" class="podium-card" :class="'place-'+(index+1)"><div class="podium-medal">{{ medal(index) }}</div><div class="podium-name">{{ row.name }}</div><div class="podium-points">{{ row.points }} Punkte</div><div class="podium-meta">{{ row.games }} Spiele · {{ row.wins }} Siege</div></div></div></template>
<script setup>
defineProps({ topRows: Array })
function medal(i){return i===0?'🥇':i===1?'🥈':'🥉'}
</script>
