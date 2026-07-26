<template>
  <div class="ranking-list">
    <article
      v-for="(r, i) in rows"
      :key="r.id"
      class="ranking-row ranking-row-compact"
    >
      <button
        class="ranking-avatar-button"
        type="button"
        title="Spielerkarte öffnen"
        @click="$emit('select-player', r)"
      >
        <AvatarPreview :avatar="r" compact />
      </button>

      <button
        class="ranking-content ranking-content-button"
        type="button"
        title="Spielerkarte öffnen"
        @click="$emit('select-player', r)"
      >
        <div class="ranking-title-small">
          {{ r.selected_title_name || 'Kein Titel' }}
        </div>
        <div class="ranking-name-main">{{ r.name }} <RankTrend :change="r.rank_change" /></div>
        <div class="ranking-points-main">
  {{ formatPoints(r.points) }} Punkte
</div>
        <div class="ranking-meta">
           {{ r.games }} Spiele · {{ formatWinRate(r.win_rate) }} % Siege · Ø {{ formatAverage(r.average_points) }} Punkte
          
        </div>
      </button>

      <div class="dynamic-rank-badge" :aria-label="`${startAt + i}. Platz`">
        <img :src="rankBadgeIcon" alt="" />
        <span>{{ startAt + i }}</span>
      </div>
    </article>
  </div>
</template>

<script setup>
import AvatarPreview from './avatar/AvatarPreview.vue'
import RankTrend from './RankTrend.vue'

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

defineEmits(['select-player'])

const rankBadgeIcon = `${import.meta.env.BASE_URL}icons/rank-badge-empty.svg`

function formatWinRate(value) {
  const number = Number(value || 0)
  return Number.isInteger(number) ? String(number) : number.toFixed(1)
}

function formatAverage(value) {
  const number = Number(value || 0)
  return Number.isInteger(number) ? String(number) : number.toFixed(1)
}

function formatPoints(value) {
  const number = Number(value || 0)

  return Number.isInteger(number)
    ? String(number)
    : number.toFixed(1).replace('.', ',')
}
</script>

<style scoped>
.ranking-avatar-button,
.ranking-content-button{
  border:0;
  background:transparent;
  padding:0;
  text-align:left;
  font:inherit;
  color:inherit;
  cursor:pointer;
}

.ranking-avatar-button{
  width:100%;
  height:100%;
  display:block;
}

.ranking-content-button{
  width:100%;
}

.ranking-meta{
  display:flex;
  align-items:center;
  gap:6px;
  flex-wrap:wrap;
}

.ranking-title-small{
  font-size:11px;
  color:#7c2d12;
  font-weight:900;
  margin-bottom:2px;
}
</style>
