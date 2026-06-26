<template>
<section class="screen"><div class="card pixel-card menu-window hero-card"><h2><span class="headline-icon">🏆</span> Podium</h2><div class="menu-body"><Podium :top-rows="ranking.slice(0,3)" /></div></div><div class="card pixel-card menu-window"><h2>Gesamtrangliste</h2><div class="menu-body"><RankingTable :rows="ranking" /></div></div></section>
</template>
<script setup>
import RankingTable from '../components/RankingTable.vue'
import Podium from '../components/Podium.vue'
defineProps({ ranking:Array })
</script>
