<template>
  <section>
    <div class="card">
      <h2>Top 3</h2>
      <RankingTable :rows="ranking.slice(0, 3)" />
    </div>
    <div class="card">
      <h2>Offene Spiele</h2>
      <p v-if="openMatches.length === 0" class="muted">Aktuell sind keine offenen Spiele vorhanden.</p>
      <MatchCard v-for="match in openMatches" :key="match.id" :match="match" :number="matchNumber(match)" :editable="false" :name-of="nameOf" />
    </div>
    <div class="card">
      <h2>Regeln</h2>
      <p class="rules-text">{{ rules }}</p>
    </div>
  </section>
</template>
<script setup>
import RankingTable from '../components/RankingTable.vue'
import MatchCard from '../components/MatchCard.vue'
defineProps({ ranking: Array, openMatches: Array, rules: String, matchNumber: Function, nameOf: Function })
</script>
