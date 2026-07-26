<template>
<section class="screen">
  <div class="card pixel-card menu-window">
    <div class="section-head">
      <h2>
        <img class="section-title-icon" :src="calendarIcon" alt="" />
        Spielplan
      </h2>
      <span class="mini-counter">{{ matches.length }} Spiele</span>
    </div>

    <div class="menu-body">
      <p v-if="matches.length===0" class="muted">Noch keine Spiele angelegt.</p>

      <div class="match-stack">
        <MatchCard
          v-for="m in sortedMatches"
          :key="m.id"
          :match="m"
          :number="matchNumber(m)"
          :editable="false"
          :name-of="nameOf"
        />
      </div>
    </div>
  </div>
</section>
</template>

<script setup>
import { computed } from 'vue'
import MatchCard from '../components/MatchCard.vue'

const props = defineProps({
  matches: { type: Array, default: () => [] },
  matchNumber: Function,
  nameOf: Function
})

const calendarIcon = `${import.meta.env.BASE_URL}icons/calendar.png`

const sortedMatches = computed(() =>
  [...props.matches].sort((a, b) => {
    const openA = !isFinished(a)
    const openB = !isFinished(b)

    // Offene/aktuelle Spiele immer zuerst.
    if (openA !== openB) return openA ? -1 : 1

    // Innerhalb der Gruppe das zuletzt angelegte Spiel zuerst.
    return matchTime(b) - matchTime(a)
  })
)

function isFinished(match) {
  return (
    match.score_a !== null &&
    match.score_b !== null &&
    match.score_a !== '' &&
    match.score_b !== ''
  )
}

function matchTime(match) {
  const value = match.created_at || match.createdAt || ''
  const parsed = Date.parse(value)

  if (!Number.isNaN(parsed)) return parsed

  // Fallback für Datensätze ohne Zeitstempel:
  // Die zuletzt geladene Position wird nach oben sortiert.
  return props.matches.findIndex(item => item.id === match.id)
}
</script>
