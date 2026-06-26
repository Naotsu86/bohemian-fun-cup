<template>
  <article class="match pixel-panel" :class="{ finished }">
    <div class="match-head"><span class="pixel-badge">🏐 Spiel {{ number }} · {{ String(match.mode).replace('v',' gegen ') }}</span><button v-if="editable" class="btn danger small-btn" @click="$emit('delete', match.id)">Löschen</button></div>
    <div class="versus-layout">
      <div class="team team-a"><b>Team A</b><div v-for="id in match.team_a" :key="id">{{ nameOf(id) }}</div></div>
      <div class="versus-score">
        <template v-if="editable"><div class="score-inputs"><input type="number" min="0" max="99" :value="match.score_a ?? ''" placeholder="A" @change="$emit('score',{ id: match.id, side: 'score_a', value: val($event.target.value) })"><span>:</span><input type="number" min="0" max="99" :value="match.score_b ?? ''" placeholder="B" @change="$emit('score',{ id: match.id, side: 'score_b', value: val($event.target.value) })"></div><small>Ergebnis</small></template>
        <template v-else><strong>{{ match.score_a ?? '–' }}:{{ match.score_b ?? '–' }}</strong><small>{{ finished ? 'Beendet' : 'Geplant' }}</small></template>
      </div>
      <div class="team team-b"><b>Team B</b><div v-for="id in match.team_b" :key="id">{{ nameOf(id) }}</div></div>
    </div>
  </article>
</template>
<script setup>
import { computed } from 'vue'
const props = defineProps({ match: Object, number: Number, editable: Boolean, nameOf: Function })
defineEmits(['delete','score'])
const finished = computed(() => props.match.score_a !== null && props.match.score_b !== null)
function val(v){ return v === '' ? null : Number(v) }
</script>
