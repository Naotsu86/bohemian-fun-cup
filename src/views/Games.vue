<template>
  <section>
    <div class="card">
      <h2>Spielplan & Ergebnisse <span class="badge readonly">nur Anzeige</span></h2>
      <p v-if="matches.length === 0" class="muted">Noch keine Spiele angelegt.</p>
      <MatchCard
        v-for="match in matches"
        :key="match.id"
        :match="match"
        :number="matchNumber(match)"
        :editable="false"
        :name-of="nameOf"
      />
    </div>
  </section>
</template>

<script setup>
import MatchCard from '../components/MatchCard.vue'

defineProps({
  matches: Array,
  matchNumber: Function,
  nameOf: Function,
})
</script>
