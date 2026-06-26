<template>
  <div class="podium">
    <div v-for="(row, index) in topRows" :key="row.id" class="podium-card" :class="'place-' + (index + 1)">
      <div class="rank-medal">{{ medal(index) }}</div>

      <div class="podium-content">
        <div class="podium-name">{{ row.name }}</div>
        <div class="podium-points">{{ row.points }} Punkte</div>
        <div class="podium-meta">{{ row.games }} Spiele · {{ row.wins }} Siege</div>
      </div>

      <div class="rank-crown">{{ crown(index) }}</div>
    </div>
  </div>
</template>

<script setup>
defineProps({ topRows: Array })

function medal(i) {
  return i === 0 ? '🥇' : i === 1 ? '🥈' : '🥉'
}

function crown(i) {
  return i === 0 ? '♛' : i === 1 ? '♕' : '♜'
}
</script>
