<template>
<section>
  <div class="card pixel-card">
    <div class="section-head">
      <h2><span class="headline-icon">🏐</span> Spielplan</h2>
      <span class="mini-counter">{{ matches.length }} Spiele</span>
    </div>

    <p v-if="matches.length===0" class="muted">Noch keine Spiele angelegt.</p>
    <MatchCard v-for="m in matches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="false" :name-of="nameOf" />
  </div>
</section>
</template>

<script setup>
import MatchCard from '../components/MatchCard.vue'
defineProps({ matches:Array, matchNumber:Function, nameOf:Function })
</script>
