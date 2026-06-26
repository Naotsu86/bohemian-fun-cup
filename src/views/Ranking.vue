<template>
<section>
  <div class="card pixel-card hero-card">
    <h2><span class="headline-icon">🏆</span> Podium</h2>
    <Podium :top-rows="ranking.slice(0,3)" />
  </div>

  <div class="card pixel-card">
    <h2>Gesamtrangliste</h2>
    <RankingTable :rows="ranking" />
  </div>
</section>
</template>

<script setup>
import RankingTable from '../components/RankingTable.vue'
import Podium from '../components/Podium.vue'

defineProps({ ranking:Array })
</script>
