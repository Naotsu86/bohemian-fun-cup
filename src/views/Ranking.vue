<template>
  <section>
    <div class="card">
      <h2>Rangliste</h2>
      <RankingTable :rows="ranking" />
    </div>
  </section>
</template>

<script setup>
import RankingTable from '../components/RankingTable.vue'

defineProps({
  ranking: Array,
})
</script>
