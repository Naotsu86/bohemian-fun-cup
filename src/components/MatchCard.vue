<template>
  <div class="match pixel-panel">
    <div class="match-head">
      <span class="pixel-badge">Spiel {{ number }} · {{ String(match.mode).replace('v',' gegen ') }}</span>
      <button v-if="editable" class="btn danger small-btn" @click="$emit('delete', match.id)">Löschen</button>
    </div>

    <div class="versus-layout">
      <div class="team">
        <b>Team A</b>
        <div v-for="id in match.team_a" :key="id">{{ nameOf(id) }}</div>
      </div>

      <div class="versus-score">
        <template v-if="editable">
          <input type="number" min="0" max="99" :value="match.score_a ?? ''" placeholder="A" @change="$emit('score',{ id: match.id, side: 'score_a', value: val($event.target.value) })">
          <span>:</span>
          <input type="number" min="0" max="99" :value="match.score_b ?? ''" placeholder="B" @change="$emit('score',{ id: match.id, side: 'score_b', value: val($event.target.value) })">
        </template>
        <template v-else>
          <strong>{{ match.score_a ?? '–' }}:{{ match.score_b ?? '–' }}</strong>
          <small>{{ finished ? 'Beendet' : 'Geplant' }}</small>
        </template>
      </div>

      <div class="team">
        <b>Team B</b>
        <div v-for="id in match.team_b" :key="id">{{ nameOf(id) }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ match: Object, number: Number, editable: Boolean, nameOf: Function })
defineEmits(['delete','score'])

const finished = computed(() => props.match.score_a !== null && props.match.score_b !== null)

function val(v) {
  return v === '' ? null : Number(v)
}
</script>
