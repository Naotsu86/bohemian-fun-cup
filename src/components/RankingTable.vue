<template>
  <div class="ranking-list">
    <article v-for="(r, i) in rows" :key="r.id" class="ranking-row ranking-row-compact">
      <div class="ranking-badge-number">
        {{ startAt + i }}
      </div>

      <div class="ranking-name">
        <b>{{ r.name }}</b>
        <small>{{ r.games }} Spiele · {{ r.wins }} Siege · Ø {{ r.avg }}</small>
      </div>

      <div class="ranking-points">{{ r.points }}</div>
    </article>
  </div>
</template>

<script setup>
defineProps({
  rows: {
    type: Array,
    default: () => []
  },
  startAt: {
    type: Number,
    default: 1
  }
})
</script>
