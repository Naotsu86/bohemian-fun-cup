<template>
  <div class="podium">
    <article v-for="(row, index) in topRows" :key="row.id" class="podium-card" :class="'place-' + (index + 1)">
      <div class="podium-content">
        <div class="podium-name">{{ row.name }}</div>
        <div class="podium-points">{{ row.points }} Punkte</div>
        <div class="podium-meta">{{ row.games }} Spiele · {{ row.wins }} Siege</div>
      </div>

      <img class="place-badge" :src="badge(index)" :alt="`${index + 1}. Platz`" />
    </article>
  </div>
</template>

<script setup>
defineProps({ topRows: Array })

const base = import.meta.env.BASE_URL

function badge(index) {
  if (index === 0) return `${base}badges/first.png`
  if (index === 1) return `${base}badges/second.png`
  return `${base}badges/third.png`
}
</script>
