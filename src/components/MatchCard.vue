<template>
  <div class="match pixel-panel">
    <div class="match-head">
      <span class="pixel-badge">Spiel {{ number }} · {{ String(match.mode).replace('v',' gegen ') }}</span>
      <button v-if="editable" class="btn danger small-btn" @click="$emit('delete', match.id)">Löschen</button>
    </div>

    <div class="teams">
      <div class="team">
        <b>Team A</b>
        <div v-for="id in match.team_a" :key="id">{{ nameOf(id) }}</div>
      </div>
      <div class="team">
        <b>Team B</b>
        <div v-for="id in match.team_b" :key="id">{{ nameOf(id) }}</div>
      </div>
    </div>

    <div class="score">
      <input v-if="editable" type="number" min="0" max="99" :value="match.score_a ?? ''" placeholder="A" @change="$emit('score',{ id: match.id, side: 'score_a', value: val($event.target.value) })">
      <div v-else class="scorebox">{{ match.score_a ?? '–' }}</div>

      <div class="colon">:</div>

      <input v-if="editable" type="number" min="0" max="99" :value="match.score_b ?? ''" placeholder="B" @change="$emit('score',{ id: match.id, side: 'score_b', value: val($event.target.value) })">
      <div v-else class="scorebox">{{ match.score_b ?? '–' }}</div>
    </div>
  </div>
</template>

<script setup>
defineProps({ match: Object, number: Number, editable: Boolean, nameOf: Function })
defineEmits(['delete','score'])

function val(v) {
  return v === '' ? null : Number(v)
}
</script>
