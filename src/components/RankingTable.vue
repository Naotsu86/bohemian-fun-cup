<template>
  <div class="ranking-list">
    <article v-for="(r,i) in rows" :key="r.id" class="ranking-row" :class="{ podiumline: i < 3 }">
      <div class="ranking-place">{{ i + 1 }}</div>
      <div class="ranking-name"><b>{{ r.name }}</b><small>{{ r.games }} Spiele · {{ r.wins }} Siege · Ø {{ r.avg }}</small></div>
      <div class="ranking-points">{{ r.points }}</div>
    </article>
  </div>
</template>
<script setup>
defineProps({ rows: Array })
</script>
