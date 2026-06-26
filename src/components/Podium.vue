<template>
  <div class="podium">
    <article v-for="(row, index) in topRows" :key="row.id" class="podium-card" :class="'place-' + (index + 1)">
      <div class="rank-medal"><span>{{ index + 1 }}</span></div>
      <div class="podium-content"><div class="podium-name">{{ row.name }}</div><div class="podium-points">{{ row.points }} Punkte</div><div class="podium-meta">{{ row.games }} Spiele · {{ row.wins }} Siege</div></div>
      <div class="rank-badge">{{ badge(index) }}</div>
    </article>
  </div>
</template>
<script setup>
defineProps({ topRows: Array })
function badge(i){ return i===0?'★':i===1?'◆':'●' }
</script>
