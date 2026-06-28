<template>
<section class="screen overview-screen">
  <div class="card pixel-card menu-window hero-card">
    <h2><span class="headline-icon">🏆</span> Top 3</h2>
    <div class="menu-body">
      <Podium :top-rows="ranking.slice(0,3)" />
    </div>
  </div>

  <div class="card pixel-card menu-window compact-card">
    <h2>
      <img class="section-title-icon" :src="calendarIcon" alt="" />
      Nächstes Spiel
    </h2>
    <div class="menu-body">
      <p v-if="openMatches.length===0" class="muted">Aktuell ist kein offenes Spiel vorhanden.</p>
      <MatchCard v-else :match="openMatches[0]" :number="matchNumber(openMatches[0])" :editable="false" :name-of="nameOf" />
    </div>
  </div>

  <div class="card pixel-card menu-window rules-card">
    <h2>
      <img class="section-title-icon" :src="rulesIcon" alt="" />
      Regeln
    </h2>
    <div class="menu-body">
      <MarkdownBlock :markdown="rulesMarkdown || rules" />
    </div>
  </div>
</section>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import Podium from '../components/Podium.vue'
import MatchCard from '../components/MatchCard.vue'
import MarkdownBlock from '../components/MarkdownBlock.vue'

defineProps({ ranking:Array, openMatches:Array, rules:String, matchNumber:Function, nameOf:Function })

const base = import.meta.env.BASE_URL
const calendarIcon = `${base}icons/calendar.png`
const rulesIcon = `${base}section-icons/rules.png`
const rulesMarkdown = ref('')

onMounted(async () => {
  try {
    const response = await fetch(`${base}docs/rules.md`, { cache: 'no-store' })
    if (response.ok) {
      rulesMarkdown.value = await response.text()
    }
  } catch (error) {
    console.warn('Regeltext konnte nicht geladen werden.', error)
  }
})
</script>
