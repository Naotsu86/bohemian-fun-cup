<template>
<section>
  <div class="card pixel-card hero-card">
    <h2><span class="headline-icon">🏆</span> Top 3</h2>
    <Podium :top-rows="ranking.slice(0,3)" />
  </div>

  <div class="card pixel-card">
    <h2><span class="headline-icon">⌛</span> Nächstes Spiel</h2>
    <p v-if="openMatches.length===0" class="muted">Aktuell ist kein offenes Spiel vorhanden.</p>
    <MatchCard v-else :match="openMatches[0]" :number="matchNumber(openMatches[0])" :editable="false" :name-of="nameOf" />
  </div>

  <div class="card pixel-card rules-card">
    <h2><span class="headline-icon">📜</span> Regeln</h2>
    <p class="rules-text">{{ rules }}</p>
  </div>
</section>
</template>

<script setup>
import Podium from '../components/Podium.vue'
import MatchCard from '../components/MatchCard.vue'

defineProps({ ranking:Array, openMatches:Array, rules:String, matchNumber:Function, nameOf:Function })
</script>
