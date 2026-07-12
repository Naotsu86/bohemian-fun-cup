<template>
  <section class="screen">
    <div class="card pixel-card menu-window hero-card">
      <h2><span class="headline-icon">🏆</span> Podium</h2>
      <div class="menu-body">
        <Podium
          :top-rows="ranking.slice(0, 3)"
          @select-player="openPlayerCard"
        />
      </div>
    </div>

    <div v-if="ranking.length > 3" class="card pixel-card menu-window ranking-followup">
      <div class="menu-body">
        <RankingTable
          :rows="ranking.slice(3)"
          :start-at="4"
          @select-player="openPlayerCard"
        />
      </div>
    </div>

    <PlayerCardModal
      v-if="selectedPlayer"
      :player="selectedPlayer"
      @close="selectedPlayer = null"
    />
  </section>
</template>

<script setup>
import { ref } from 'vue'
import RankingTable from '../components/RankingTable.vue'
import Podium from '../components/Podium.vue'
import PlayerCardModal from '../components/PlayerCardModal.vue'

defineProps({ ranking: Array })

const selectedPlayer = ref(null)

function openPlayerCard(player) {
  selectedPlayer.value = player
}
</script>
