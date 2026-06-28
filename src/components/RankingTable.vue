<template>
  <div class="ranking-list">
    <article v-for="(r, i) in rows" :key="r.id" class="ranking-row ranking-row-compact">
      <div class="ranking-content">
        <div class="ranking-name-main">{{ r.name }}</div>
        <div class="ranking-points-main">{{ r.points }} Punkte</div>
        <div class="ranking-meta">{{ r.games }} Spiele · {{ r.wins }} Siege · Ø {{ r.avg }}</div>
      </div>

      <div class="rank-badge" :aria-label="`${startAt + i}. Platz`">
        <img :src="rankBadgeIcon" alt="" />
        <span>{{ startAt + i }}</span>
      </div>
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

const rankBadgeIcon = `${import.meta.env.BASE_URL}icons/rank-badge-empty.svg`
</script>
