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
        <MatchCard v-for="m in matches" :key="m.id" :match="m" :number="matchNumber(m)" :editable="false" :name-of="nameOf" />
      </div>
    </div>
  </div>
</section>
</template>

<script setup>
import MatchCard from '../components/MatchCard.vue'

defineProps({ matches:Array, matchNumber:Function, nameOf:Function })

const calendarIcon = `${import.meta.env.BASE_URL}icons/calendar.png`
</script>
